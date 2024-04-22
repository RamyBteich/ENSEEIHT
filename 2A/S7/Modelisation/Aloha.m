% Définir la plage de charge (nombre d'utilisateurs par canal)
traffic_load = 0:0.01:5;

% Calculer la probabilité de collision pour Aloha Pur
throughput_pure_aloha = traffic_load .* exp(-2 * traffic_load);


% Calculer la probabilité de collision pour Slotted Aloha
throughput_slotted_aloha = traffic_load .* exp(-traffic_load);

% Tracer les courbes
figure;
plot(traffic_load, throughput_pure_aloha, 'r', 'LineWidth', 2, 'DisplayName', 'Pure Aloha');
hold on;
plot(traffic_load, throughput_slotted_aloha, 'b', 'LineWidth', 2, 'DisplayName', 'Slotted Aloha');
title('Débit en fonction de la charge - Aloha Pur vs Aloha Évidé');
legend('location','best');
xlabel('charge');
ylabel('debit');