import os
import time
import socket
from flask import Flask, render_template, jsonify, Response
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST

app = Flask(__name__)

# Prometheus Metrics
REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP Requests', ['method', 'endpoint', 'status'])
REQUEST_LATENCY = Histogram('http_request_duration_seconds', 'HTTP Request Latency', ['endpoint'])

APP_VERSION = os.getenv("APP_VERSION", "v1.0.0")
ENVIRONMENT = os.getenv("ENVIRONMENT", "production")
AWS_REGION = os.getenv("AWS_REGION", "ap-south-1")
POD_NAME = os.getenv("POD_NAME", socket.gethostname())
NODE_NAME = os.getenv("NODE_NAME", "aws-eks-managed-node")
NAMESPACE = os.getenv("NAMESPACE", "production")

START_TIME = time.time()

@app.before_request
def before_request():
    pass

@app.route("/")
def index():
    REQUEST_COUNT.labels(method="GET", endpoint="/", status=200).inc()
    uptime_seconds = int(time.time() - START_TIME)
    return render_template(
        "index.html",
        version=APP_VERSION,
        environment=ENVIRONMENT,
        region=AWS_REGION,
        pod_name=POD_NAME,
        node_name=NODE_NAME,
        namespace=NAMESPACE,
        uptime=f"{uptime_seconds}s"
    )

@app.route("/healthz")
def healthz():
    REQUEST_COUNT.labels(method="GET", endpoint="/healthz", status=200).inc()
    return jsonify({"status": "healthy", "timestamp": time.time()}), 200

@app.route("/readyz")
def readyz():
    REQUEST_COUNT.labels(method="GET", endpoint="/readyz", status=200).inc()
    return jsonify({"status": "ready", "pod": POD_NAME}), 200

@app.route("/metrics")
def metrics():
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)

@app.route("/api/info")
def info():
    return jsonify({
        "app": "complete-eks-devsecops-platform",
        "version": APP_VERSION,
        "environment": ENVIRONMENT,
        "region": AWS_REGION,
        "pod": POD_NAME,
        "node": NODE_NAME,
        "namespace": NAMESPACE,
        "uptime_seconds": int(time.time() - START_TIME)
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
