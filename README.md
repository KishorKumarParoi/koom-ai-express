# 🎬 KoomAI Real-Time Media Ingestion & WebRTC Service

[![Node.js](https://img.shields.io/badge/Node.js-v20%2B-339933?logo=node.js&logoColor=white)](https://nodejs.org/)
[![Bun](https://img.shields.io/badge/Bun-v1.2%2B-000000?logo=bun&logoColor=white)](https://bun.sh/)
[![Express](https://img.shields.io/badge/Express-5.1-black?logo=express&logoColor=white)](https://expressjs.com/)
[![Socket.IO](https://img.shields.io/badge/Socket.IO-v4.8-010101?logo=socket.io&logoColor=white)](https://socket.io/)
[![AWS S3](https://img.shields.io/badge/AWS_S3-Storage-569A31?logo=amazons3&logoColor=white)](https://aws.amazon.com/s3/)
[![OpenAI](https://img.shields.io/badge/OpenAI-Whisper_%26_GPT--3.5-412991?logo=openai&logoColor=white)](https://openai.com/)
[![License: ISC](https://img.shields.io/badge/License-ISC-blue.svg)](https://opensource.org/licenses/ISC)

> High-throughput real-time video streaming, WebRTC signalling, and AI automated transcription backend for the **KoomAI Enterprise Video Platform**. Connects directly with the **KoomAI Desktop Client (Electron)**, **KoomAI Chrome Extension (Manifest V3)**, and **KoomAI Web Cockpit (Next.js 16)**.

---

## ⚡ Quickstart

### 1. One-Click Automated Deployment
```bash
./deploy.sh
```

Or run in background daemon mode:
```bash
./deploy.sh --daemon
```

### 2. Zero-Cost Instant Teardown
```bash
./clear.sh
```

---

## 📡 REST & Socket.IO Endpoints

| Protocol | Path / Event | Description |
| :--- | :--- | :--- |
| **HTTP GET** | `/` | Service information, version, and endpoints directory |
| **HTTP GET** | `/health` | Health probe (AWS S3, OpenAI, active sessions) |
| **HTTP GET** | `/ready` | Kubernetes & Docker readiness probe |
| **HTTP GET** | `/metrics` | Real-time telemetry (active connections, chunks, memory) |
| **HTTP POST** | `/api/upload` | Direct multipart base64 upload for Chrome extension |
| **HTTP GET** | `/uploads/:filename` | Local video preview fallback when S3 is bypassed |
| **Socket.IO** | `video-chunks` | Streaming binary WebM chunk ingestion |
| **Socket.IO** | `process-video` | Triggers S3 upload, Whisper AI transcription, and webhooks |
| **Socket.IO** | `join-room` | WebRTC room joining |
| **Socket.IO** | `webrtc-offer` / `answer` | SDP exchange for peer-to-peer live video |
| **Socket.IO** | `ice-candidate` | Interactive Connectivity Establishment for low latency |

---

## 🔧 Environment Variables (`.env`)

```ini
PORT=5001
NEXT_API_HOST=http://localhost:3000/api
ELECTRON_HOST=http://localhost:5173
BUCKET_NAME=koom-ai
ACCESS_KEY=your_aws_access_key
SECRET_KEY=your_aws_secret_key
BUCKET_REGION=us-east-1
OPENAI_SECRET_KEY=your_openai_key
```

*Note: If AWS or OpenAI keys are absent, the server automatically degrades gracefully into local storage mode (`/uploads/`) with automated fallback metadata.*

---

## 🏛️ Architecture & System Design
For full system design diagrams and trade-off analyses, see [ARCHITECTURE.md](file:///Users/kishorkumarparoi/job-project/koom-ai-express/ARCHITECTURE.md).
