package com.example.mynewapp;

import android.bluetooth.BluetoothAdapter;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import android.Manifest;

public class MainActivity extends AppCompatActivity implements View.OnClickListener {

    // Constantes pour les requêtes de permissions Bluetooth
    private static final int REQUEST_BLUETOOTH_CONNECT = 1;
    private static final int REQUEST_ENABLE_BT = 2;

    private BluetoothAdapter bleutooth; // Adaptateur Bluetooth
    private Button client_btn; // Bouton pour le client
    private Button server_btn; // Bouton pour le serveur

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        getSupportActionBar().hide(); // Masquer la barre d'action

        bleutooth = BluetoothAdapter.getDefaultAdapter(); // Initialiser l'adaptateur Bluetooth

        // Initialiser les boutons et définir les écouteurs d'événements
        Button btn = (Button) findViewById(R.id.display_but);
        btn.setOnClickListener(this);

        client_btn = (Button) findViewById(R.id.client);
        client_btn.setOnClickListener(this);

        server_btn = (Button) findViewById(R.id.server);
        server_btn.setOnClickListener(this);
    }

    @Override
    public void onClick(View v) {
        if (v.getId() == R.id.display_but) {
            // Lancer l'activité d'affichage des appareils
            Intent displayIntent = new Intent(this, display.class);
            displayIntent.putExtra("name", "DEVICES");
            startActivity(displayIntent);
        } else if (v.getId() == R.id.client) {
            // Vérifier les permissions Bluetooth et lancer l'activité client
            if (bluetoothpermission()) {
                if (ensureBluetoothEnabled()) {
                    clientactivity();
                } else {
                    Toast.makeText(this, "Please turn on Bluetooth", Toast.LENGTH_SHORT).show();
                }
            }
        } else if (v.getId() == R.id.server) {
            // Vérifier les permissions Bluetooth et lancer l'activité serveur
            if (bluetoothpermission()) {
                if (ensureBluetoothEnabled()) {
                    serveractivity();
                } else {
                    Toast.makeText(this, "Please turn on Bluetooth", Toast.LENGTH_SHORT).show();
                }
            }
        }
    }

    // Méthode pour vérifier les permissions Bluetooth
    private boolean bluetoothpermission() {
        if (bleutooth != null) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                // Vérifier la permission BLUETOOTH_CONNECT pour les versions Android S et ultérieures
                if (ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
                    ActivityCompat.requestPermissions(this, new String[]{Manifest.permission.BLUETOOTH_CONNECT}, REQUEST_BLUETOOTH_CONNECT);
                    return false;
                }
            }
        }
        return true;
    }

    // Méthode pour s'assurer que Bluetooth est activé
    private boolean ensureBluetoothEnabled() {
        if (bleutooth != null && !bleutooth.isEnabled()) {
            return false;
        }
        return true;
    }

    // Lancer l'activité serveur
    private void serveractivity() {
        Intent serverIntent = new Intent(this, Server_Activity.class);
        serverIntent.putExtra("name", "DEVICES");
        startActivity(serverIntent);
    }

    // Lancer l'activité client
    private void clientactivity() {
        Intent clientIntent = new Intent(this, Client_Activity.class);
        clientIntent.putExtra("name", "DEVICES");
        startActivity(clientIntent);
    }

    // Gérer les résultats des requêtes de permissions
    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == REQUEST_BLUETOOTH_CONNECT) {
            if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                // La permission est accordée, lancer l'activité appropriée
                if (server_btn.isPressed()) {
                    serveractivity();
                } else if (client_btn.isPressed()) {
                    clientactivity();
                }
            } else {
                // La permission est refusée, afficher un message expliquant pourquoi cette permission est importante
                Toast.makeText(this, "Bluetooth permission is required for this app to function", Toast.LENGTH_LONG).show();
            }
        }
    }
}
