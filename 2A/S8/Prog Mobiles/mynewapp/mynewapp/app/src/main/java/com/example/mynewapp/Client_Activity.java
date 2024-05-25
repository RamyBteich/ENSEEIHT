package com.example.mynewapp;

import android.annotation.SuppressLint;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothSocket;
import android.graphics.Typeface;
import android.os.Bundle;
import android.os.Handler;
import android.util.Log;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.ToggleButton;
import androidx.appcompat.app.AppCompatActivity;
import com.android.volley.RequestQueue;
import com.android.volley.toolbox.JsonArrayRequest;
import com.android.volley.toolbox.Volley;
import org.json.JSONArray;
import org.json.JSONObject;
import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.UUID;

public class Client_Activity extends AppCompatActivity {
    private static final String URL = "https://www.bde.enseeiht.fr/~bailleq/smartHouse/api/v1/devices/42";
    private static final String SERVER_MAC_ADDRESS = "78:46:D4:E9:11:E8"; // Remplacer par l'adresse MAC du serveur
    private static final UUID MY_UUID = UUID.fromString("5289df73-7df5-3326-bcdd-22597afb1fac");
    private static final String TAG = "Client_Activity";
    private LinearLayout linearLayout;
    private RequestQueue queue;
    private Handler handler;
    private Runnable runnableCode;

    @SuppressLint("MissingInflatedId")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_client);
        getSupportActionBar().setTitle("Smart House - Client");

        // Initialiser le LinearLayout et la file de requêtes réseau (RequestQueue)
        linearLayout = findViewById(R.id.linearLayout);
        queue = Volley.newRequestQueue(this);

        // Récupérer les appareils et se connecter au serveur Bluetooth
        fetchDevices();
        connectToServer();
    }

    // Méthode pour récupérer les appareils depuis l'API
    private void fetchDevices() {
        // Création de la requête JSON pour obtenir les données des appareils
        JsonArrayRequest jsonArrayRequest = new JsonArrayRequest(URL, this::displayDevices, error -> {
            // Gestion des erreurs de la requête réseau
            Log.e(TAG, "Error fetching devices", error);
        });

        // Configuration du Handler pour effectuer des requêtes périodiques
        handler = new Handler();
        runnableCode = new Runnable() {
            @Override
            public void run() {
                // Ajouter la requête à la file et la répéter toutes les 10 secondes
                queue.add(jsonArrayRequest);
                handler.postDelayed(this, 10000);
            }
        };
        // Démarrer les mises à jour
        handler.post(runnableCode);
        queue.add(jsonArrayRequest);
    }

    // Méthode pour se connecter au serveur Bluetooth
    private void connectToServer() {
        // Initialiser l'adaptateur Bluetooth
        BluetoothAdapter bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        if (bluetoothAdapter == null) {
            // Vérifier si Bluetooth est supporté
            Log.e(TAG, "Bluetooth not supported on this device");
            return;
        }

        // Obtenir l'appareil serveur par son adresse MAC
        BluetoothDevice serverDevice = bluetoothAdapter.getRemoteDevice(SERVER_MAC_ADDRESS);
        new Thread(new Runnable() {
            @Override
            public void run() {
                BluetoothSocket socket = null;
                try {
                    // Créer et connecter un socket Bluetooth
                    socket = serverDevice.createRfcommSocketToServiceRecord(MY_UUID);
                    socket.connect();
                    InputStream inputStream = socket.getInputStream();
                    BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream));

                    // Lire les commandes en boucle et les appliquer
                    while (true) {
                        String command = reader.readLine();
                        if (command != null) {
                            runOnUiThread(() -> applyCommand(command));
                        }
                    }
                } catch (Exception e) {
                    // Gestion des erreurs de connexion
                    Log.e(TAG, "Error connecting to server", e);
                    if (socket != null) {
                        try {
                            socket.close();
                        } catch (Exception closeException) {
                            Log.e(TAG, "Error closing socket", closeException);
                        }
                    }
                }
            }
        }).start();
    }

    // Appliquer les commandes reçues du serveur
    private void applyCommand(String command) {
        try {
            // Diviser la commande en ID de l'appareil et action
            String[] parts = command.split(":");
            int id = Integer.parseInt(parts[0]);
            String action = parts[1];
            // Trouver l'appareil par son ID et mettre à jour son état
            for (int i = 0; i < linearLayout.getChildCount(); i++) {
                RelativeLayout deviceLayout = (RelativeLayout) linearLayout.getChildAt(i);
                TextView secondLine = deviceLayout.findViewById(R.id.secondline);
                String text = secondLine.getText().toString();
                if (text.contains("ID: " + id)) {
                    ToggleButton toggleButton = deviceLayout.findViewById(R.id.switchstatus);
                    toggleButton.setChecked(action.equals("turnOn"));
                    break;
                }
            }
        } catch (Exception e) {
            // Gestion des erreurs d'application des commandes
            Log.e(TAG, "Error applying command", e);
        }
    }

    // Afficher les appareils dans l'interface utilisateur
    public void displayDevices(JSONArray response) {
        // Effacer les vues précédentes
        linearLayout.removeAllViews();
        try {
            // Parcourir la réponse JSON pour obtenir les informations de chaque appareil
            for (int i = 0; i < response.length(); i++) {
                JSONObject device = response.getJSONObject(i);

                // Créer un layout pour chaque appareil
                RelativeLayout relativeLayout = createDeviceLayout();

                TextView firstLine = relativeLayout.findViewById(R.id.firstline);
                TextView secondLine = relativeLayout.findViewById(R.id.secondline);
                ToggleButton toggleButton = relativeLayout.findViewById(R.id.switchstatus);

                // Récupérer les informations de l'appareil depuis le JSON
                String brand = device.getString("BRAND");
                String name = device.getString("NAME");
                String type = device.getString("TYPE");
                String data = device.getString("DATA");
                String model = device.getString("MODEL");
                int autonomy = device.getInt("AUTONOMY");
                int state = device.getInt("STATE");
                int id = device.getInt("ID");

                // Formater les informations à afficher
                String first = "[" + brand + " " + model + "] " + name;
                String second = "Autonomy: " + autonomy + "%" + "    " + "Data: " + data + "\nType: " + type + "    " + "ID: " + id;
                boolean status = state == 1;

                // Mettre à jour les vues avec les informations de l'appareil
                firstLine.setText(first);
                secondLine.setText(second);
                toggleButton.setChecked(status);

                // Ajouter le layout de l'appareil au LinearLayout principal
                linearLayout.addView(relativeLayout);
            }
        } catch (Exception e) {
            // Gestion des erreurs d'affichage des appareils
            Log.e(TAG, "Error displaying devices", e);
        }
    }

    // Créer un layout pour chaque appareil
    private RelativeLayout createDeviceLayout() {
        // Création d'un RelativeLayout pour chaque appareil
        RelativeLayout relativeLayout = new RelativeLayout(this);
        RelativeLayout.LayoutParams layoutParams = new RelativeLayout.LayoutParams(
                RelativeLayout.LayoutParams.MATCH_PARENT,
                RelativeLayout.LayoutParams.WRAP_CONTENT
        );
        relativeLayout.setLayoutParams(layoutParams);
        relativeLayout.setPadding(16, 16, 16, 16);

        // Création et configuration du TextView pour la première ligne (nom de l'appareil)
        TextView firstLineTextView = new TextView(this);
        firstLineTextView.setId(R.id.firstline);
        RelativeLayout.LayoutParams firstLineLayoutParams = new RelativeLayout.LayoutParams(RelativeLayout.LayoutParams.WRAP_CONTENT, RelativeLayout.LayoutParams.WRAP_CONTENT);
        firstLineLayoutParams.addRule(RelativeLayout.ALIGN_PARENT_START);
        firstLineTextView.setLayoutParams(firstLineLayoutParams);
        firstLineTextView.setTextSize(16);
        firstLineTextView.setTypeface(firstLineTextView.getTypeface(), Typeface.BOLD);
        relativeLayout.addView(firstLineTextView);

        // Création et configuration du TextView pour la deuxième ligne (détails de l'appareil)
        TextView secondLineTextView = new TextView(this);
        secondLineTextView.setId(R.id.secondline);
        RelativeLayout.LayoutParams secondLineLayoutParams = new RelativeLayout.LayoutParams(RelativeLayout.LayoutParams.WRAP_CONTENT, RelativeLayout.LayoutParams.WRAP_CONTENT);
        secondLineLayoutParams.addRule(RelativeLayout.BELOW, R.id.firstline);
        secondLineTextView.setLayoutParams(secondLineLayoutParams);
        secondLineTextView.setTextSize(12);
        relativeLayout.addView(secondLineTextView);

        // Création et configuration du ToggleButton pour l'état de l'appareil
        ToggleButton toggleButton = new ToggleButton(this);
        toggleButton.setId(R.id.switchstatus);
        RelativeLayout.LayoutParams toggleButtonLayoutParams = new RelativeLayout.LayoutParams(RelativeLayout.LayoutParams.WRAP_CONTENT, RelativeLayout.LayoutParams.WRAP_CONTENT);
        toggleButtonLayoutParams.addRule(RelativeLayout.ALIGN_PARENT_END);
        toggleButtonLayoutParams.addRule(RelativeLayout.CENTER_VERTICAL);
        toggleButton.setBackgroundColor(android.graphics.Color.TRANSPARENT);
        toggleButton.setLayoutParams(toggleButtonLayoutParams);
        relativeLayout.addView(toggleButton);

        return relativeLayout;
    }
}
