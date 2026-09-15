"""MQTT dashboard for the Lab 0.3 ESP32-C6 node."""

import json
import logging
import os
import threading

import paho.mqtt.client as mqtt
from flask import Flask, jsonify, render_template_string, request

app = Flask(__name__)
logging.getLogger("werkzeug").setLevel(logging.ERROR)

MQTT_BROKER = os.environ.get("MQTT_BROKER", "localhost")
MQTT_PORT = 1883
TOPIC_SENSOR = "iot/sensor"
TOPIC_CONTROL = "iot/control"
latest_sensor_data = {"error": "Waiting for first message..."}
sensor_lock = threading.Lock()


def on_connect(client, userdata, flags, reason_code, properties):
    print(f"[MQTT] Connected to broker (rc={reason_code})")
    client.subscribe(TOPIC_SENSOR, qos=0)
    print(f"[MQTT] Subscribed to: {TOPIC_SENSOR}")


def on_message(client, userdata, msg):
    global latest_sensor_data
    try:
        data = json.loads(msg.payload.decode())
    except (UnicodeDecodeError, json.JSONDecodeError):
        data = {"raw": msg.payload.decode(errors="replace")}
    with sensor_lock:
        latest_sensor_data = data


mqtt_client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)
mqtt_client.on_connect = on_connect
mqtt_client.on_message = on_message

HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>IoT Lab: MQTT Dashboard</title>
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
  <style>
    body { font-family: system-ui, sans-serif; background:#f4f4f9; padding:2rem;
           max-width:800px; margin:0 auto; color:#333; }
    .card { background:white; padding:1.5rem; border-radius:8px;
            box-shadow:0 4px 6px rgba(0,0,0,.1); margin-bottom:1.5rem; }
    .btn-group { display:flex; gap:1rem; margin-top:1rem; }
    .btn { flex:1; padding:1rem; font-size:1rem; border:0; border-radius:4px;
           cursor:pointer; color:white; font-weight:bold; }
    .btn-on { background:#28a745; } .btn-off { background:#dc3545; }
    .status { font-family:monospace; font-size:.9rem; color:#666; }
  </style>
</head>
<body>
  <h2>IoT Systems Design Lab: MQTT</h2>
  <p class="status">Broker: {{ broker }}:{{ port }}</p>
  <div class="card"><h3>Sensing Capability (SUB: {{ topic_sensor }})</h3>
    <canvas id="telemetryChart" height="100"></canvas>
    <p class="status" id="conn-status">Waiting for data from broker...</p>
  </div>
  <div class="card"><h3>Actuating Capability (PUB: {{ topic_control }})</h3>
    <div class="btn-group">
      <button class="btn btn-on" onclick="controlLight(1)">Turn ON</button>
      <button class="btn btn-off" onclick="controlLight(0)">Turn OFF</button>
    </div>
  </div>
  <script>
    const chart = new Chart(document.getElementById('telemetryChart'), {
      type:'line', data:{labels:[],datasets:[{label:'Temperature (C)',
      borderColor:'#0056b3',data:[],fill:false,tension:.1}]},
      options:{animation:false,scales:{y:{beginAtZero:false}}}
    });
    function fetchSensorData() {
      fetch('/api/sensor').then(res => res.json()).then(data => {
        const status = document.getElementById('conn-status');
        if (data.error) { status.innerText='Waiting: '+data.error; }
        else if (data.temperature !== undefined) {
          status.innerText='Receiving MQTT messages. Live data stream active.';
          status.style.color='green';
          chart.data.labels.push(new Date().toLocaleTimeString());
          chart.data.datasets[0].data.push(data.temperature);
          if (chart.data.labels.length > 20) {
            chart.data.labels.shift(); chart.data.datasets[0].data.shift();
          }
          chart.update();
        }
      });
    }
    function controlLight(state) {
      fetch('/api/control', {method:'POST', headers:{'Content-Type':'application/json'},
        body:JSON.stringify({state:state})}).then(res => res.json()).then(data => {
          if (data.status !== 'ok') alert('Failed to publish MQTT command.');
        });
    }
    setInterval(fetchSensorData, 1500);
  </script>
</body>
</html>
"""


@app.route("/")
def index():
    return render_template_string(
        HTML_TEMPLATE,
        broker=MQTT_BROKER,
        port=MQTT_PORT,
        topic_sensor=TOPIC_SENSOR,
        topic_control=TOPIC_CONTROL,
    )


@app.route("/api/sensor", methods=["GET"])
def api_sensor():
    with sensor_lock:
        return jsonify(latest_sensor_data)


@app.route("/api/control", methods=["POST"])
def api_control():
    data = request.get_json(silent=True) or {}
    result = mqtt_client.publish(
        TOPIC_CONTROL, json.dumps({"state": data.get("state", 0)}), qos=1
    )
    if result.rc == mqtt.MQTT_ERR_SUCCESS:
        return jsonify({"status": "ok"}), 200
    return jsonify({"status": "error", "message": "MQTT publish failed"}), 502


if __name__ == "__main__":
    mqtt_client.connect(MQTT_BROKER, MQTT_PORT, keepalive=60)
    mqtt_client.loop_start()
    print("[*] MQTT Dashboard running.")
    print(f"[*] Broker: {MQTT_BROKER}:{MQTT_PORT}")
    print(f"[*] Subscribed to: {TOPIC_SENSOR}")
    print(f"[*] Publishing control to: {TOPIC_CONTROL}")
    app.run(host="0.0.0.0", port=5000)
