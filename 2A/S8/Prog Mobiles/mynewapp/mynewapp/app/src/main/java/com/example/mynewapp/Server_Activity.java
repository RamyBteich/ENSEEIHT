package com.example.mynewapp;

import androidx.core.app.ActivityCompat;
import android.annotation.SuppressLint;
import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothServerSocket;
import android.bluetooth.BluetoothSocket;
import android.content.pm.PackageManager;
import android.graphics.Typeface;
import android.os.Bundle;
import android.os.Handler;
import android.view.View;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.Toast;
import android.widget.ToggleButton;

import com.android.volley.Request;
import com.android.volley.RequestQueue;
import com.android.volley.toolbox.JsonArrayRequest;
import com.android.volley.toolbox.StringRequest;
import com.android.volley.toolbox.Volley;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.IOException;
import java.io.OutputStream;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

public class Server_Activity extends Activity {

    // Déclaration des variables pour le layout, la file de requêtes, le Handler et le Bluetooth
    private LinearLayout linearLayout;
    private RequestQueue queue;
    private Handler handler;
    private Runnable runnableCode;
    private static final String URL = "https://www.bde.enseeiht.fr/~bailleq/smartHouse/api/v1/devices/42";
    private BluetoothSocket clientSocket;
    private OutputStream outputStream;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_server);

        // Initialisation de l'adaptateur Bluetooth
        BluetoothAdapter bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        BluetoothServerSocket serverSocket = null;

        try {
            // Vérification de la permission BLUETOOTH_CONNECT
            if (ActivityCompat.checkSelfPermission(this, "android.permission.BLUETOOTH_CONNECT") != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(this, new String[]{"android.permission.BLUETOOTH_CONNECT"}, 1);
                return;
            }

            // Création d'un serveur Bluetooth avec un UUID spécifique pour identifier le service
            UUID uuid = UUID.fromString("5289df73-7df5-3326-bcdd-22597afb1fac");
            serverSocket = bluetoothAdapter.listenUsingRfcommWithServiceRecord("MonServeur", uuid);

            BluetoothServerSocket finalServerSocket = serverSocket;
            // Création d'un thread pour accepter les connexions entrantes
            new Thread(new Runnable() {
                @Override
                public void run() {
                    try {
                        // Accepter une connexion entrante
                        clientSocket = finalServerSocket.accept();
                        outputStream = clientSocket.getOutputStream();
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                }
            }).start();

        } catch (IOException e) {
            e.printStackTrace();
        }

        // Initialisation du layout et de la file de requêtes pour les appels réseau
        linearLayout = findViewById(R.id.serv);
        queue = Volley.newRequestQueue(this);

        // Appel de la méthode pour récupérer les appareils depuis l'API
        fetchDevices();
    }

    // Méthode pour récupérer les appareils depuis l'API et les afficher
    private void fetchDevices() {
        // Création de la requête JSON pour obtenir les données des appareils
        JsonArrayRequest jsonArrayRequest = new JsonArrayRequest(URL, this::displayDevices, error -> {
            Toast.makeText(Server_Activity.this, "Error fetching devices", Toast.LENGTH_SHORT).show();
        });

        // Configuration d'un Handler pour des mises à jour périodiques
        handler = new Handler();
        runnableCode = new Runnable() {
            @Override
            public void run() {
                // Ajout de la requête à la file et répétition toutes les 10 secondes
                queue.add(jsonArrayRequest);
                handler.postDelayed(this, 10000); // Mise à jour toutes les 10 secondes
            }
        };
        handler.post(runnableCode);
        queue.add(jsonArrayRequest);
    }

    // Méthode pour afficher les appareils dans le layout
    public void displayDevices(JSONArray response) {
        // Effacer les vues précédentes
        linearLayout.removeAllViews();
        try {
            // Parcourir la réponse JSON pour obtenir les informations de chaque appareil
            for (int i = 0; i < response.length(); i++) {
                JSONObject device = response.getJSONObject(i);

                // Création d'un layout pour chaque appareil
                RelativeLayout relativeLayout = createDeviceLayout();

                // Récupération des vues du layout
                TextView firstLine = relativeLayout.findViewById(R.id.firstline);
                TextView secondLine = relativeLayout.findViewById(R.id.secondline);
                ToggleButton toggleButton = relativeLayout.findViewById(R.id.switchstatus);

                // Récupération des informations de l'appareil depuis le JSON
                String brand = device.getString("BRAND");
                String name = device.getString("NAME");
                String type = device.getString("TYPE");
                String data = device.getString("DATA");
                String model = device.getString("MODEL");
                int autonomy = device.getInt("AUTONOMY");
                int state = device.getInt("STATE");
                int id = device.getInt("ID");

                // Formatage des informations pour les afficher
                String first = "[" + brand + " " + model + "] " + name;
                String second = "Autonomy: " + autonomy + "%" + "    " + "Data: " + data + "\nType: " + type + "    " + "ID: " + id;
                boolean status = state == 1;

                // Mise à jour des vues avec les informations de l'appareil
                firstLine.setText(first);
                secondLine.setText(second);
                toggleButton.setChecked(status);

                // Ajout d'un écouteur pour le ToggleButton pour changer l'état de l'appareil
                toggleButton.setOnClickListener(new View.OnClickListener() {
                    boolean currentStatus = status;

                    @Override
                    public void onClick(View v) {
                        // Changer l'état actuel
                        currentStatus = !currentStatus;
                        toggleButton.setChecked(currentStatus);
                        // Mise à jour de l'état de l'appareil sur le serveur
                        updateDeviceState(id, currentStatus ? "OFF" : "ON");
                        // Envoi de la commande au client via Bluetooth
                        sendCommandToClient(id, currentStatus ? "OFF" : "ON");
                    }
                });

                // Ajout du layout de l'appareil au LinearLayout principal
                linearLayout.addView(relativeLayout);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    // Méthode pour mettre à jour l'état de l'appareil sur le serveur
    private void updateDeviceState(int id, String action) {
        String url = "https://www.bde.enseeiht.fr/~bailleq/smartHouse/api/v1/devices/";
        StringRequest postRequest = new StringRequest(Request.Method.POST, url,
                response -> {
                    // Gérer la réponse du serveur
                },
                error -> {
                    // Gérer les erreurs de la requête
                }) {
            @Override
            protected Map<String, String> getParams() {
                // Définir les paramètres de la requête POST
                Map<String, String> params = new HashMap<>();
                params.put("deviceId", String.valueOf(id));
                params.put("houseId", "42");
                params.put("action", action);
                return params;
            }
        };
        // Ajouter la requête à la file de requêtes
        queue.add(postRequest);
    }

    // Méthode pour envoyer une commande au client via Bluetooth
    private void sendCommandToClient(int id, String action) {
        if (outputStream != null) {
            try {
                // Créer la commande sous forme de chaîne de caractères
                String command = id + ":" + action;
                // Envoyer la commande via le flux de sortie Bluetooth
                outputStream.write(command.getBytes());
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    }

    // Méthode pour créer le layout de l'appareil
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
        // Rendre le texte en gras
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
        toggleButton.setBackgroundColor(android.graphics.Color.TRANSPARENT); // Rendre le fond du bouton transparent
        toggleButton.setLayoutParams(toggleButtonLayoutParams);
        relativeLayout.addView(toggleButton);

        return relativeLayout;
    }
}
