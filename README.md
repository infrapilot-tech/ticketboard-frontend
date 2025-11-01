# TicketBoard Frontend

Frontend user interface for the TicketBoard application, built with React and served via Nginx.

## 📚 Related Documentation

- **Main Project:** [../README.md](../README.md) - Complete project overview and deployment
- **Architecture:** [../ARCHITECTURE.md](../ARCHITECTURE.md) - System architecture and design
- **Backend Service:** [../ticketboard-backend/README.md](../ticketboard-backend/README.md) - Express REST API
- **GitHub Actions Setup:** [../GITHUB_ACTIONS_SETUP.md](../GITHUB_ACTIONS_SETUP.md) - CI/CD configuration

## 🎯 Overview

The TicketBoard Frontend is a React-based single-page application (SPA) that provides an intuitive interface for managing tickets. It communicates with the backend API to create and display tickets in real-time.

### Key Features

- ✅ Modern React 18 with Hooks
- ✅ Real-time ticket listing
- ✅ Create new tickets
- ✅ RESTful API integration
- ✅ Responsive design
- ✅ Production-ready with Nginx
- ✅ Dockerized multi-stage build

## 🛠️ Tech Stack

- **Framework:** React 18.3.1
- **Build Tool:** Create React App (react-scripts)
- **HTTP Client:** Fetch API
- **Production Server:** Nginx (Alpine)
- **Container:** Docker (multi-stage build)

## 📋 Prerequisites

- Node.js 18+ (for local development)
- npm (comes with Node.js)
- Docker (optional, for containerization)
- Backend API running (see [ticketboard-backend](../ticketboard-backend/README.md))

## 🚀 Quick Start

### Local Development

1. **Install dependencies:**
   ```bash
   npm install
   ```

2. **Configure backend URL (optional):**
   ```bash
   # Create .env file
   echo "REACT_APP_API_URL=http://localhost:3000" > .env
   ```

3. **Start development server:**
   ```bash
   npm start
   ```

4. **Open browser:**
   ```
   http://localhost:3000
   ```

   The app will automatically reload when you make changes.

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `REACT_APP_API_URL` | `http://localhost:3000` | Backend API base URL |

**Examples:**

```bash
# Local development
REACT_APP_API_URL=http://localhost:3000 npm start

# Production with external API
REACT_APP_API_URL=https://api.yourdomain.com npm start

# Kubernetes (built into deployment)
REACT_APP_API_URL=http://ticketboard-backend.ticketboard.svc.cluster.local:3000
```

## 📦 Build for Production

### Create Production Build

```bash
npm run build
```

This creates an optimized production build in the `build/` folder:
- Minified JavaScript and CSS
- Hashed filenames for caching
- Optimized assets
- Source maps (optional)

### Serve Production Build Locally

```bash
# Install serve globally
npm install -g serve

# Serve the build folder
serve -s build -l 3000
```

## 🐳 Docker

### Build Image

```bash
docker build -t ticketboard-frontend:latest .
```

### Run Container

```bash
# Default configuration
docker run -p 80:80 ticketboard-frontend:latest

# With custom backend URL (requires rebuild)
docker build --build-arg REACT_APP_API_URL=http://api.example.com -t ticketboard-frontend:latest .
docker run -p 80:80 ticketboard-frontend:latest
```

### Docker Image Details

**Multi-stage Build:**

1. **Stage 1 - Build (node:18-alpine):**
   - Install dependencies
   - Build production assets
   - Output to `/app/build`

2. **Stage 2 - Production (nginx:alpine):**
   - Copy built assets to Nginx
   - Serve static files
   - Minimal image size (~30MB)

**Size:** ~30MB (optimized with Alpine Linux)

## ☸️ Kubernetes Deployment

### Deploy to Cluster

```bash
# From ticketboard-frontend directory
cd k8s

# Create namespace (if not exists)
kubectl apply -f namespace.yaml

# Deploy frontend
kubectl apply -f frontend-deployment.yaml
kubectl apply -f frontend-service.yaml
```

### Kubernetes Resources

**Deployment:**
- Replicas: 2 (High Availability)
- Resource requests: 100m CPU, 128Mi Memory
- Resource limits: 250m CPU, 256Mi Memory
- Container port: 80
- Backend URL configured via env var

**Service:**
- Type: LoadBalancer
- Port: 80
- Target Port: 80
- External access for users

### Verify Deployment

```bash
# Check pods
kubectl get pods -n ticketboard -l app=ticketboard-frontend

# Check service
kubectl get svc -n ticketboard ticketboard-frontend

# Get external IP/URL
kubectl get svc ticketboard-frontend -n ticketboard -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# View logs
kubectl logs -n ticketboard -l app=ticketboard-frontend --tail=50

# Port forward for local testing
kubectl port-forward -n ticketboard svc/ticketboard-frontend 8080:80
```

## 🔄 Integration with Backend

The frontend communicates with the [TicketBoard Backend](../ticketboard-backend/README.md) via REST API.

### API Integration

API calls are centralized in `src/api.js`:

```javascript
const API_BASE_URL = process.env.REACT_APP_API_URL || "http://localhost:3000";

export const getTickets = async () => {
  const res = await fetch(`${API_BASE_URL}/tickets`);
  return res.json();
};

export const createTicket = async (title) => {
  const res = await fetch(`${API_BASE_URL}/tickets`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ title }),
  });
  return res.json();
};
```

### Connection Configurations

**Local Development:**
```bash
# Start backend
cd ../ticketboard-backend
npm start  # Runs on http://localhost:3000

# Start frontend (in another terminal)
cd ../ticketboard-frontend
npm start  # Runs on http://localhost:3000 (with proxy)
```

**Kubernetes:**
```yaml
env:
  - name: REACT_APP_API_URL
    value: "http://ticketboard-backend.ticketboard.svc.cluster.local:3000"
```

## 🧪 Testing

### Run Tests

```bash
npm test
```

**Note:** Tests are not yet implemented. Current command is a placeholder.

### Manual Testing

1. **Start the application:**
   ```bash
   npm start
   ```

2. **Test features:**
   - Open http://localhost:3000
   - View existing tickets
   - Enter a new ticket title
   - Click "Add" button
   - Verify ticket appears in the list

3. **Test API connectivity:**
   ```bash
   # Check browser console for API calls
   # Should see successful fetch requests to backend
   ```

## 📁 Project Structure

```
ticketboard-frontend/
├── README.md                  # This file
├── Dockerfile                 # Multi-stage container build
├── package.json               # Dependencies and scripts
├── package-lock.json          # Locked dependency versions
├── public/                    # Static assets
│   ├── index.html            # HTML template
│   └── favicon.ico           # App icon
├── src/                       # Source code
│   ├── index.js              # App entry point
│   ├── App.js                # Main component
│   └── api.js                # API client functions
└── k8s/                       # Kubernetes manifests
    ├── namespace.yaml        # Namespace definition
    ├── frontend-deployment.yaml  # Deployment configuration
    └── frontend-service.yaml     # Service configuration
```

## 🎨 Component Overview

### App Component (`src/App.js`)

Main application component that handles:
- State management for tickets and input
- Fetching tickets from API on mount
- Creating new tickets
- Rendering UI

**Key Functions:**
- `fetchTickets()` - Retrieves all tickets from backend
- `handleAdd()` - Creates a new ticket
- `useEffect()` - Loads tickets on component mount

### API Module (`src/api.js`)

Centralized API client with:
- `getTickets()` - GET /tickets
- `createTicket(title)` - POST /tickets

## 🔧 Development

### Adding New Features

**Example: Delete Ticket**

1. **Add API function** (`src/api.js`):
   ```javascript
   export const deleteTicket = async (id) => {
     await fetch(`${API_BASE_URL}/tickets/${id}`, {
       method: "DELETE",
     });
   };
   ```

2. **Update component** (`src/App.js`):
   ```javascript
   const handleDelete = async (id) => {
     await deleteTicket(id);
     fetchTickets();
   };
   ```

3. **Add button to UI:**
   ```jsx
   <button onClick={() => handleDelete(t.id)}>Delete</button>
   ```

### Styling

Current implementation uses inline styles. To use CSS:

1. **Create CSS file** (`src/App.css`):
   ```css
   .container {
     padding: 2rem;
     font-family: Arial, sans-serif;
   }
   ```

2. **Import in component:**
   ```javascript
   import './App.css';
   ```

### Adding Libraries

```bash
# UI framework
npm install @mui/material @emotion/react @emotion/styled

# State management
npm install redux react-redux @reduxjs/toolkit

# Routing
npm install react-router-dom

# HTTP client
npm install axios
```

## 📦 Container Registry

Images are published to GitHub Container Registry (GHCR):

```bash
# Pull image
docker pull ghcr.io/ghostgto/ticketboard-frontend:latest

# Run from registry
docker run -p 80:80 ghcr.io/ghostgto/ticketboard-frontend:latest
```

### Building and Pushing

```bash
# Build with build arg
docker build \
  --build-arg REACT_APP_API_URL=http://your-api-url \
  -t ghcr.io/YOUR_USERNAME/ticketboard-frontend:latest .

# Login to GHCR
echo $GHCR_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin

# Push
docker push ghcr.io/YOUR_USERNAME/ticketboard-frontend:latest
```

## 🔐 Security Considerations

1. **Environment Variables:** API URLs should be configured at build time
2. **HTTPS:** Use HTTPS in production for secure communication
3. **CORS:** Backend must allow frontend origin
4. **Content Security Policy:** Configure Nginx headers
5. **Dependencies:** Regularly update packages for security patches

### Recommended Enhancements

- [ ] Add authentication (JWT, OAuth)
- [ ] Implement error boundaries
- [ ] Add loading states
- [ ] Implement error handling
- [ ] Add form validation
- [ ] Enable HTTPS/SSL
- [ ] Add security headers in Nginx

## 🐛 Troubleshooting

### Port 3000 Already in Use

```bash
# Find process
lsof -i :3000

# Kill process
kill -9 <PID>

# Or use different port
PORT=3001 npm start
```

### Module Not Found

```bash
# Clean install
rm -rf node_modules package-lock.json
npm install
```

### API Connection Failed

```bash
# Check backend is running
curl http://localhost:3000/healthz

# Check CORS settings in backend
# Check REACT_APP_API_URL is correct
echo $REACT_APP_API_URL

# Check browser console for errors
```

### Docker Build Fails

```bash
# Clear Docker cache
docker builder prune -a

# Rebuild without cache
docker build --no-cache -t ticketboard-frontend:latest .
```

### Kubernetes Pod Not Starting

```bash
# Check pod status
kubectl describe pod -n ticketboard <pod-name>

# Check logs
kubectl logs -n ticketboard <pod-name>

# Common issues:
# - Image pull errors (check GHCR access)
# - Backend URL incorrect
# - Resource limits too low
```

### Blank Page in Production

```bash
# Check build completed successfully
npm run build

# Check Nginx logs in container
docker logs <container-id>

# Verify API URL is correct at build time
```

## 📊 Performance

### Bundle Analysis

```bash
# Install analyzer
npm install --save-dev webpack-bundle-analyzer

# Analyze bundle
npm run build
npx webpack-bundle-analyzer build/static/js/*.js
```

### Optimization Tips

- Code splitting with React.lazy()
- Memoization with React.memo()
- Virtual scrolling for large lists
- Image optimization
- CDN for static assets

## 🤝 Contributing

See the [main project README](../README.md) for contribution guidelines.

## 📝 License

MIT - See [main project README](../README.md) for details.

## 👤 Author

Gustavo Tejeda

## 🔗 Links

- **Main Project:** [TicketBoard](../README.md)
- **Backend:** [ticketboard-backend](../ticketboard-backend/README.md)
- **Docker Hub:** [ghcr.io/ghostgto/ticketboard-frontend](https://ghcr.io/ghostgto/ticketboard-frontend)
- **Issues:** Report bugs and request features in the main repository
- **Create React App:** [Documentation](https://create-react-app.dev/)

---

**Part of the TicketBoard Project** | [View Full Documentation](../README.md)
