"""Minimal HTTP dashboard for the Lab 0 ESP32-C6 node."""

from flask import Flask, jsonify, render_template_string, request
import requests

app = Flask(__name__)

ESP32_IP = "192.168.1.15"


def get_sensor_data():
    try:
        response = requests.get(f"http://{ESP32_IP}/api/sensor", timeout=2)
        if response.status_code == 200:
            return response.json()
        return {"error": f"HTTP {response.status_code}"}
    except requests.exceptions.RequestException:
        return {"error": "Node Unreachable"}


def control_light(state):
    try:
        response = requests.post(
            f"http://{ESP32_IP}/api/control",
            json={"state": state},
            timeout=2,
        )
        return response.status_code == 200
    except requests.exceptions.RequestException:
        return False


HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>IoT Lab: Wi-Fi Dashboard</title>
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
  <style>
    body { font-family: system-ui, sans-serif; background:#f4f4f9;
           padding:2rem; max-width:800px; margin:0 auto; color:#333; }
    .card { background:white; padding:1.5rem; border-radius:8px;
            box-shadow:0 4px 6px rgba(0,0,0,.1); margin-bottom:1.5rem; }
    .btn-group { display:flex; gap:1rem; margin-top:1rem; }
    .btn { flex:1; padding:1rem; font-size:1rem; border:0;
           border-radius:4px; cursor:pointer; color:white; font-weight:bold; }
    .btn-on { background:#28a745; } .btn-off { background:#dc3545; }
    .status { font-family:monospace; font-size:.9rem; color:#666; }
  </style>
</head>
<body>
  <h2>IoT Systems Design Lab: Minimal Implementation</h2>
  <p class="status">Target Node: {{ esp_ip }} (Wi-Fi/HTTP)</p>
  <div class="card">
    <h3>Sensing Capability (Live Telemetry)</h3>
    <canvas id="telemetryChart" height="100"></canvas>
    <p class="status" id="conn-status">Waiting for data...</p>
  </div>
  <div class="card">
    <h3>Actuating Capability (LED Control)</h3>
    <div class="btn-group">
      <button class="btn btn-on" onclick="controlLight(1)">Turn ON</button>
      <button class="btn btn-off" onclick="controlLight(0)">Turn OFF</button>
    </div>
  </div>
  <script>
    const chart = new Chart(document.getElementById('telemetryChart'), {
      type:'line',
      data:{labels:[],datasets:[{label:'Temperature (°C)',borderColor:'#0056b3',
             data:[],fill:false,tension:.1}]},
      options:{animation:false,scales:{y:{beginAtZero:false}}}
    });
    function updateChart(temp) {
      chart.data.labels.push(new Date().toLocaleTimeString());
      chart.data.datasets[0].data.push(temp);
      if (chart.data.labels.length > 20) {
        chart.data.labels.shift(); chart.data.datasets[0].data.shift();
      }
      chart.update();
    }
    function fetchSensorData() {
      fetch('/api/sensor').then(res => res.json()).then(data => {
        const status = document.getElementById('conn-status');
        if (data.error) {
          status.innerText = 'Error: ' + data.error; status.style.color = 'red';
        } else if (data.temperature !== undefined) {
          status.innerText = 'Connected. Live data stream active.';
          status.style.color = 'green'; updateChart(data.temperature);
        }
      });
    }
    function controlLight(state) {
      fetch('/api/control', {
        method:'POST', headers:{'Content-Type':'application/json'},
        body:JSON.stringify({state:state})
      }).then(res => res.json()).then(data => {
        if (data.status !== 'ok') alert('Failed to route command to ESP32.');
      });
    }
    setInterval(fetchSensorData, 1500);
    fetchSensorData();
  </script>
</body>
</html>
"""


@app.route("/")
def index():
    return render_template_string(HTML_TEMPLATE, esp_ip=ESP32_IP)


@app.route("/api/sensor", methods=["GET"])
def api_sensor():
    return jsonify(get_sensor_data())


@app.route("/api/control", methods=["POST"])
def api_control():
    data = request.get_json(silent=True) or {}
    state = data.get("state", 0)
    if control_light(state):
        return jsonify({"status": "ok"}), 200
    return jsonify({"status": "error"}), 502


if __name__ == "__main__":
    print(f"[*] Dashboard running. Target ESP32 IP: {ESP32_IP}")
    app.run(host="0.0.0.0", port=5000)
