package com.example.mynewapp;

import android.annotation.SuppressLint;
import android.content.Intent;
import android.graphics.Typeface;
import android.os.Bundle;
import android.os.Handler;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;

import androidx.appcompat.app.AppCompatActivity;

import com.android.volley.Request;
import com.android.volley.RequestQueue;
import com.android.volley.toolbox.JsonArrayRequest;
import com.android.volley.toolbox.StringRequest;
import com.android.volley.toolbox.Volley;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.HashMap;
import java.util.Map;

public class display extends AppCompatActivity {
    String url = "https://www.bde.enseeiht.fr/~bailleq/smartHouse/api/v1/devices/42";
    private LinearLayout linearLayout;
    private RequestQueue queue;
    private Handler handler;
    private Runnable runnableCode;

    @SuppressLint("MissingInflatedId")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_display);
        getSupportActionBar().setTitle("Smart House");

        linearLayout = findViewById(R.id.linearLayout); // Initialiser le LinearLayout
        queue = Volley.newRequestQueue(this); // Initialiser la file de requêtes
        JsonArrayRequest jsonArrayRequest = new JsonArrayRequest(url, this::fetching, error -> {
            // Gestion des erreurs ici si nécessaire
        });

        // Mises à jour périodiques avec Handler
        handler = new Handler();
        runnableCode = new Runnable() {
            @Override
            public void run() {
                queue.add(jsonArrayRequest); // Ajouter la requête à la file
                handler.postDelayed(this, 10000); // Délai de 10 secondes
            }
        };
        handler.post(runnableCode); // Commencer les mises à jour périodiques

        queue.add(jsonArrayRequest); // Ajouter la requête initiale à la file
    }

    // Méthode pour traiter la réponse JSON de l'API
    public void fetching(JSONArray response) {
        try {
            for (int i = 0; i < response.length(); i++) {
                JSONObject responses = response.getJSONObject(i);

                RelativeLayout relativeLayout = relativelayout(); // Créer un nouveau RelativeLayout

                TextView firstline = relativeLayout.findViewById(R.id.firstline);
                TextView secondline = relativeLayout.findViewById(R.id.secondline);
                Button toggleButton = relativeLayout.findViewById(R.id.switchstatus);

                // Récupérer les données de l'appareil depuis le JSON
                String brand = responses.getString("BRAND");
                String name = responses.getString("NAME");
                String type = responses.getString("TYPE");
                String data = responses.getString("DATA");
                String model = responses.getString("MODEL");
                int autonomy = responses.getInt("AUTONOMY");
                int state = responses.getInt("STATE");
                int id = responses.getInt("ID");

                // Formater les chaînes à afficher
                String first = "[" + brand + " " + model + "] " + name;
                String second = "Autonomy: " + autonomy + "%" + "    " + "Data: " + data + "\nType: " + type + "    " + "ID: " + id;
                boolean status = state == 1;

                firstline.setText(first);
                secondline.setText(second);
                toggleButton.setText(status ? "ON" : "OFF");

                // Ajouter un OnClickListener pour le bouton de basculement
                toggleButton.setOnClickListener(new View.OnClickListener() {
                    boolean currentStatus = status; // Suivre l'état actuel

                    @Override
                    public void onClick(View v) {
                        currentStatus = !currentStatus; // Basculer l'état
                        toggleButton.setText(currentStatus ? "ON" : "OFF");

                        // URL pour la requête POST
                        String toggleUrl = "https://www.bde.enseeiht.fr/~bailleq/smartHouse/api/v1/devices/42";
                        StringRequest postRequest = new StringRequest(Request.Method.POST, toggleUrl,
                                response -> {
                                    // Gérer la réponse
                                },
                                error -> {
                                    // Gérer l'erreur
                                }) {
                            @Override
                            protected Map<String, String> getParams() {
                                // Paramètres de la requête POST
                                Map<String, String> params = new HashMap<>(); // Ajouter le paramètre deviceId avec la valeur de l'identifiant de l'appareil
                                params.put("deviceId", String.valueOf(id)); // Ajouter le paramètre deviceId avec la valeur de l'identifiant de l'appareil

                                params.put("houseId", "42"); // Ajouter le paramètre houseId avec la valeur "42"(42 identifianr de la maison)
                                params.put("action", currentStatus ? "turnOn" : "turnOff");// Ajouter le paramètre action avec la valeur "turnOn" ou "turnOff" en fonction de l'état actuel de l'appareil
                                return params;
                            }
                        };
                        queue.add(postRequest); // Ajouter la requête POST à la file
                    }
                });

                linearLayout.addView(relativeLayout); // Ajouter le RelativeLayout au LinearLayout
            }
        } catch (Exception e) {
            e.printStackTrace(); // Gérer les exceptions
        }
    }

    // Méthode pour créer et configurer un RelativeLayout
    public RelativeLayout relativelayout() {
        RelativeLayout.LayoutParams layoutParams = new RelativeLayout.LayoutParams(
                RelativeLayout.LayoutParams.MATCH_PARENT,
                RelativeLayout.LayoutParams.WRAP_CONTENT
        );
        RelativeLayout relativeLayout = new RelativeLayout(this);
        relativeLayout.setLayoutParams(layoutParams);
        relativeLayout.setPadding(16, 16, 16, 16);

        TextView firstLineTextView = new TextView(this);
        firstLineTextView.setId(R.id.firstline);
        RelativeLayout.LayoutParams firstLineLayoutParams = new RelativeLayout.LayoutParams(RelativeLayout.LayoutParams.WRAP_CONTENT, RelativeLayout.LayoutParams.WRAP_CONTENT);
        firstLineLayoutParams.addRule(RelativeLayout.ALIGN_PARENT_START);
        firstLineTextView.setLayoutParams(firstLineLayoutParams);
        firstLineTextView.setText("");
        firstLineTextView.setTextSize(16);
        firstLineTextView.setTypeface(null, Typeface.BOLD);
        relativeLayout.addView(firstLineTextView);

        TextView secondLineTextView = new TextView(this);
        secondLineTextView.setId(R.id.secondline);
        RelativeLayout.LayoutParams secondLineLayoutParams = new RelativeLayout.LayoutParams(RelativeLayout.LayoutParams.WRAP_CONTENT, RelativeLayout.LayoutParams.WRAP_CONTENT);
        secondLineLayoutParams.addRule(RelativeLayout.BELOW, R.id.firstline);
        secondLineLayoutParams.addRule(RelativeLayout.ALIGN_PARENT_START);
        secondLineTextView.setLayoutParams(secondLineLayoutParams);
        secondLineTextView.setText("");
        secondLineTextView.setTypeface(null, Typeface.ITALIC);
        secondLineTextView.setTextSize(12);
        relativeLayout.addView(secondLineTextView);

        Button toggleButton = new Button(this);
        toggleButton.setId(R.id.switchstatus);
        RelativeLayout.LayoutParams buttonLayoutParams = new RelativeLayout.LayoutParams(RelativeLayout.LayoutParams.WRAP_CONTENT, RelativeLayout.LayoutParams.WRAP_CONTENT);
        buttonLayoutParams.addRule(RelativeLayout.ALIGN_PARENT_END);
        buttonLayoutParams.addRule(RelativeLayout.CENTER_VERTICAL);
        toggleButton.setLayoutParams(buttonLayoutParams);
        toggleButton.setBackgroundColor(android.graphics.Color.TRANSPARENT); // Rendre le fond du bouton transparent
        relativeLayout.addView(toggleButton);

        return relativeLayout;
    }
}
