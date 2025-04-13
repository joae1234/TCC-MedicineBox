import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LEDControlPage(),
    );
  }
}

class LEDControlPage extends StatefulWidget {
  const LEDControlPage({super.key});
  @override
  State<LEDControlPage> createState() => _LEDControlPageState();
}

class _LEDControlPageState extends State<LEDControlPage> {
  late MqttBrowserClient client;
  bool conectado = false;
  bool ledLigado = false;

  @override
  void initState() {
    super.initState();
    conectarMQTT();
  }

  Future<void> conectarMQTT() async {
    client = MqttBrowserClient('wss://mqtt.eclipseprojects.io/mqtt', 'flutter_web_client_${DateTime.now().millisecondsSinceEpoch}'); // Use um Client ID único
    client.port = 443;
    client.websocketProtocols = ['mqtt'];
    client.setProtocolV311();
    client.keepAlivePeriod = 30;
    // client.autoReconnect = true; // Considere desativar durante o debug inicial
    client.logging(on: true);

    client.onConnected = () {
      print("✅ Conectado ao broker");
      if (mounted) { // Boa prática: verificar se o widget ainda está na árvore
        setState(() => conectado = true);
      }
    };

    client.onDisconnected = () {
      print("❌ Desconectado do broker");
       if (mounted) { // Boa prática
        setState(() => conectado = false);
       }
    };

    // MENSAGEM DE CONEXÃO SIMPLIFICADA:
    final connMessage = MqttConnectMessage()
        .withClientIdentifier(client.clientIdentifier) // Reutilize o client ID do construtor
        .startClean(); // Não defina WillQos se não usar WillTopic/WillMessage

    client.connectionMessage = connMessage;

    try {
      print("ℹ Tentando conectar...");
      await client.connect();
    } catch (e) {
      print("Erro ao conectar: $e");
      client.disconnect();
       if (mounted) { // Boa prática
         setState(() => conectado = false); // Garante que o estado seja atualizado em caso de erro
       }
    }
  }

  void enviarComando(String comando) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(comando);
    client.publishMessage(
      'comando/led',
      MqttQos.atLeastOnce,
      builder.payload!,
    );
    print("Comando enviado: $comando");

    setState(() {
      ledLigado = comando == "on";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Controle do LED via Web")),
      body: Center(
        child: conectado
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    ledLigado ? "LED está LIGADO" : "LED está DESLIGADO",
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => enviarComando("on"),
                    child: const Text("Ligar LED"),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => enviarComando("off"),
                    child: const Text("Desligar LED"),
                  ),
                ],
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
} 