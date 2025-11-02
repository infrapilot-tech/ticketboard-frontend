#!/bin/bash

echo "🚀 INICIANDO MIGRACIÓN COMPLETA A VITE"
echo "🔗 Conectando con backend TicketBoard..."

cd ticketboard-frontend

# 1. Backup de seguridad
echo "📦 Haciendo backup..."
cp package.json package.json.backup 2>/dev/null || true
[ -d "src" ] && cp -r src src-backup || mkdir -p src-backup
[ -f "public/index.html" ] && cp public/index.html src-backup/ 2>/dev/null || true

# 2. Limpiar dependencias antiguas de CRA
echo "🧹 Limpiando dependencias antiguas de Create React App..."
rm -rf node_modules package-lock.json build

# 3. Crear nuevo package.json optimizado para Vite
echo "📝 Creando package.json para Vite..."
cat > package.json << 'EOF'
{
  "name": "ticketboard-frontend",
  "private": true,
  "type": "module",
  "version": "1.0.0",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview",
    "lint": "eslint . --ext js,jsx --report-unused-disable-directives --max-warnings 0",
    "preview:prod": "vite preview --port 3000 --host"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.20.1",
    "axios": "^1.6.2"
  },
  "devDependencies": {
    "@vitejs/plugin-react": "^4.1.1",
    "vite": "^4.5.0"
  }
}
EOF

# 4. Instalar dependencias nuevas
echo "📥 Instalando Vite y dependencias..."
npm install

# 5. Configuración de Vite con proxy para el backend
echo "⚙️ Configurando Vite..."
cat > vite.config.js << 'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    port: 3000,
    host: true,
    proxy: {
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true,
        secure: false,
        rewrite: (path) => path.replace(/^\/api/, '')
      }
    }
  },
  build: {
    outDir: 'dist',
    sourcemap: false,
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom'],
          router: ['react-router-dom']
        }
      }
    }
  },
  optimizeDeps: {
    include: ['react', 'react-dom', 'react-router-dom']
  }
})
EOF

# 6. Crear estructura de directorios
echo "📁 Creando estructura de directorios..."
mkdir -p src/{components,pages,services,hooks,utils,context} public

# 7. Variables de entorno
echo "🔧 Configurando variables de entorno..."
cat > .env << 'EOF'
VITE_API_URL=http://localhost:8080
VITE_APP_NAME=TicketBoard
EOF

cat > .env.production << 'EOF'
VITE_API_URL=http://backend-service:8080
VITE_APP_NAME=TicketBoard
EOF

# 8. HTML principal
echo "📄 Creando index.html..."
cat > index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/vite.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>TicketBoard - Gestion de Tickets</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
EOF

# 9. Servicios API adaptados a tu backend
echo "🔌 Creando servicios para tu backend..."
cat > src/services/api.js << 'EOF'
import axios from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8080';

// Crear instancia de axios
const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 15000,
});

// Interceptores para manejar tokens y errores
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('authToken');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('authToken');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

// Servicios para Tickets (adaptados a tu backend)
export const ticketService = {
  // Obtener todos los tickets
  getAllTickets: () => api.get('/api/tickets'),
  
  // Obtener ticket por ID
  getTicketById: (id) => api.get(`/api/tickets/${id}`),
  
  // Crear nuevo ticket
  createTicket: (ticketData) => api.post('/api/tickets', ticketData),
  
  // Actualizar ticket
  updateTicket: (id, ticketData) => api.put(`/api/tickets/${id}`, ticketData),
  
  // Eliminar ticket
  deleteTicket: (id) => api.delete(`/api/tickets/${id}`),
  
  // Buscar tickets
  searchTickets: (query) => api.get(`/api/tickets/search?q=${query}`),
};

// Servicios de Autenticación
export const authService = {
  // Login
  login: (credentials) => api.post('/api/auth/login', credentials),
  
  // Registro
  register: (userData) => api.post('/api/auth/register', userData),
  
  // Verificar token
  verifyToken: () => api.get('/api/auth/verify'),
  
  // Logout
  logout: () => {
    localStorage.removeItem('authToken');
    return Promise.resolve();
  },
};

// Servicios de Usuarios
export const userService = {
  // Obtener perfil de usuario
  getProfile: () => api.get('/api/users/profile'),
  
  // Actualizar perfil
  updateProfile: (userData) => api.put('/api/users/profile', userData),
};

// Health check
export const healthService = {
  checkBackend: () => api.get('/health'),
  checkDatabase: () => api.get('/api/health/db'),
};

export default api;
EOF

# 10. Hooks personalizados
echo "🎣 Creando hooks personalizados..."
cat > src/hooks/useAuth.js << 'EOF'
import { useState, useEffect, createContext, useContext } from 'react';
import { authService } from '../services/api';

const AuthContext = createContext();

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth debe ser usado dentro de un AuthProvider');
  }
  return context;
};

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    checkAuth();
  }, []);

  const checkAuth = async () => {
    try {
      const token = localStorage.getItem('authToken');
      if (token) {
        const response = await authService.verifyToken();
        setUser(response.data);
      }
    } catch (error) {
      console.error('Error verificando autenticación:', error);
      localStorage.removeItem('authToken');
    } finally {
      setLoading(false);
    }
  };

  const login = async (credentials) => {
    try {
      const response = await authService.login(credentials);
      const { token, user } = response.data;
      
      localStorage.setItem('authToken', token);
      setUser(user);
      
      return { success: true };
    } catch (error) {
      return { 
        success: false, 
        error: error.response?.data?.message || 'Error en el login' 
      };
    }
  };

  const register = async (userData) => {
    try {
      const response = await authService.register(userData);
      const { token, user } = response.data;
      
      localStorage.setItem('authToken', token);
      setUser(user);
      
      return { success: true };
    } catch (error) {
      return { 
        success: false, 
        error: error.response?.data?.message || 'Error en el registro' 
      };
    }
  };

  const logout = () => {
    authService.logout();
    setUser(null);
  };

  const value = {
    user,
    loading,
    login,
    register,
    logout,
    isAuthenticated: !!user
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};
EOF

cat > src/hooks/useTickets.js << 'EOF'
import { useState, useEffect } from 'react';
import { ticketService } from '../services/api';

export const useTickets = () => {
  const [tickets, setTickets] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const fetchTickets = async () => {
    try {
      setLoading(true);
      setError(null);
      const response = await ticketService.getAllTickets();
      setTickets(response.data);
    } catch (err) {
      setError(err.response?.data?.message || 'Error al cargar tickets');
    } finally {
      setLoading(false);
    }
  };

  const createTicket = async (ticketData) => {
    try {
      const response = await ticketService.createTicket(ticketData);
      setTickets(prev => [response.data, ...prev]);
      return { success: true, data: response.data };
    } catch (err) {
      const errorMsg = err.response?.data?.message || 'Error al crear ticket';
      return { success: false, error: errorMsg };
    }
  };

  const updateTicket = async (id, ticketData) => {
    try {
      const response = await ticketService.updateTicket(id, ticketData);
      setTickets(prev => 
        prev.map(ticket => ticket.id === id ? response.data : ticket)
      );
      return { success: true, data: response.data };
    } catch (err) {
      const errorMsg = err.response?.data?.message || 'Error al actualizar ticket';
      return { success: false, error: errorMsg };
    }
  };

  const deleteTicket = async (id) => {
    try {
      await ticketService.deleteTicket(id);
      setTickets(prev => prev.filter(ticket => ticket.id !== id));
      return { success: true };
    } catch (err) {
      const errorMsg = err.response?.data?.message || 'Error al eliminar ticket';
      return { success: false, error: errorMsg };
    }
  };

  useEffect(() => {
    fetchTickets();
  }, []);

  return {
    tickets,
    loading,
    error,
    fetchTickets,
    createTicket,
    updateTicket,
    deleteTicket
  };
};
EOF

cat > src/hooks/useApiHealth.js << 'EOF'
import { useState, useEffect } from 'react';
import { healthService } from '../services/api';

export const useApiHealth = () => {
  const [backendStatus, setBackendStatus] = useState('checking');
  const [dbStatus, setDbStatus] = useState('checking');

  useEffect(() => {
    const checkHealth = async () => {
      try {
        // Verificar backend
        await healthService.checkBackend();
        setBackendStatus('healthy');
        
        // Verificar base de datos
        await healthService.checkDatabase();
        setDbStatus('healthy');
      } catch (error) {
        setBackendStatus('unhealthy');
        setDbStatus('unhealthy');
      }
    };

    checkHealth();
    const interval = setInterval(checkHealth, 30000); // Verificar cada 30 segundos
    
    return () => clearInterval(interval);
  }, []);

  return { backendStatus, dbStatus };
};
EOF

# 11. Componentes principales
echo "🧩 Creando componentes principales..."
cat > src/App.jsx << 'EOF'
import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './hooks/useAuth';
import { useApiHealth } from './hooks/useApiHealth';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Tickets from './pages/Tickets';
import Navbar from './components/Navbar';
import HealthStatus from './components/HealthStatus';
import './App.css';

// Componente de ruta protegida
const ProtectedRoute = ({ children }) => {
  const { isAuthenticated, loading } = useAuth();
  
  if (loading) {
    return <div className="loading">Cargando...</div>;
  }
  
  return isAuthenticated ? children : <Navigate to="/login" />;
};

function AppContent() {
  const { backendStatus, dbStatus } = useApiHealth();

  return (
    <Router>
      <div className="App">
        <HealthStatus backendStatus={backendStatus} dbStatus={dbStatus} />
        <Navbar />
        <main className="main-content">
          <Routes>
            <Route path="/login" element={<Login />} />
            <Route 
              path="/" 
              element={
                <ProtectedRoute>
                  <Dashboard />
                </ProtectedRoute>
              } 
            />
            <Route 
              path="/tickets" 
              element={
                <ProtectedRoute>
                  <Tickets />
                </ProtectedRoute>
              } 
            />
            <Route path="*" element={<Navigate to="/" />} />
          </Routes>
        </main>
      </div>
    </Router>
  );
}

function App() {
  return (
    <AuthProvider>
      <AppContent />
    </AuthProvider>
  );
}

export default App;
EOF

cat > src/main.jsx << 'EOF'
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.jsx'
import './index.css'

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
EOF

# 12. Componentes básicos
echo "🔧 Creando componentes básicos..."
cat > src/components/Navbar.jsx << 'EOF'
import React from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';

const Navbar = () => {
  const { user, logout, isAuthenticated } = useAuth();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <nav className="navbar">
      <div className="nav-brand">
        <Link to="/">🎫 TicketBoard</Link>
      </div>
      
      {isAuthenticated && (
        <div className="nav-links">
          <Link to="/">Dashboard</Link>
          <Link to="/tickets">Tickets</Link>
          <span className="user-info">Hola, {user?.username}</span>
          <button onClick={handleLogout} className="logout-btn">
            Cerrar Sesión
          </button>
        </div>
      )}
    </nav>
  );
};

export default Navbar;
EOF

cat > src/components/HealthStatus.jsx << 'EOF'
import React from 'react';

const HealthStatus = ({ backendStatus, dbStatus }) => {
  const getStatusColor = (status) => {
    switch (status) {
      case 'healthy': return '#4CAF50';
      case 'unhealthy': return '#f44336';
      default: return '#ff9800';
    }
  };

  const getStatusText = (status) => {
    switch (status) {
      case 'healthy': return 'Conectado';
      case 'unhealthy': return 'Error';
      default: return 'Verificando...';
    }
  };

  return (
    <div className="health-status">
      <div className="status-item">
        <span className="status-label">Backend:</span>
        <span 
          className="status-dot"
          style={{ backgroundColor: getStatusColor(backendStatus) }}
        ></span>
        <span className="status-text">{getStatusText(backendStatus)}</span>
      </div>
      <div className="status-item">
        <span className="status-label">Base de Datos:</span>
        <span 
          className="status-dot"
          style={{ backgroundColor: getStatusColor(dbStatus) }}
        ></span>
        <span className="status-text">{getStatusText(dbStatus)}</span>
      </div>
    </div>
  );
};

export default HealthStatus;
EOF

# 13. Páginas
echo "📄 Creando páginas..."
cat > src/pages/Login.jsx << 'EOF'
import React, { useState } from 'react';
import { useAuth } from '../hooks/useAuth';
import { useNavigate } from 'react-router-dom';

const Login = () => {
  const [isLogin, setIsLogin] = useState(true);
  const [formData, setFormData] = useState({
    username: '',
    email: '',
    password: ''
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  
  const { login, register } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      let result;
      
      if (isLogin) {
        result = await login({
          username: formData.username,
          password: formData.password
        });
      } else {
        result = await register(formData);
      }

      if (result.success) {
        navigate('/');
      } else {
        setError(result.error);
      }
    } catch (err) {
      setError('Error de conexión');
    } finally {
      setLoading(false);
    }
  };

  const handleChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    });
  };

  return (
    <div className="login-page">
      <div className="login-container">
        <h2>{isLogin ? 'Iniciar Sesión' : 'Registrarse'}</h2>
        
        {error && <div className="error-message">{error}</div>}
        
        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <input
              type="text"
              name="username"
              placeholder="Usuario"
              value={formData.username}
              onChange={handleChange}
              required
            />
          </div>
          
          {!isLogin && (
            <div className="form-group">
              <input
                type="email"
                name="email"
                placeholder="Email"
                value={formData.email}
                onChange={handleChange}
                required
              />
            </div>
          )}
          
          <div className="form-group">
            <input
              type="password"
              name="password"
              placeholder="Contraseña"
              value={formData.password}
              onChange={handleChange}
              required
            />
          </div>
          
          <button type="submit" disabled={loading}>
            {loading ? 'Cargando...' : (isLogin ? 'Iniciar Sesión' : 'Registrarse')}
          </button>
        </form>
        
        <p>
          {isLogin ? '¿No tienes cuenta?' : '¿Ya tienes cuenta?'}
          <button 
            type="button" 
            className="switch-mode"
            onClick={() => setIsLogin(!isLogin)}
          >
            {isLogin ? 'Regístrate' : 'Inicia Sesión'}
          </button>
        </p>
      </div>
    </div>
  );
};

export default Login;
EOF

cat > src/pages/Dashboard.jsx << 'EOF'
import React from 'react';
import { useTickets } from '../hooks/useTickets';
import { useAuth } from '../hooks/useAuth';

const Dashboard = () => {
  const { tickets, loading } = useTickets();
  const { user } = useAuth();

  const stats = {
    total: tickets.length,
    open: tickets.filter(t => t.status === 'OPEN').length,
    inProgress: tickets.filter(t => t.status === 'IN_PROGRESS').length,
    closed: tickets.filter(t => t.status === 'CLOSED').length
  };

  if (loading) {
    return <div className="loading">Cargando dashboard...</div>;
  }

  return (
    <div className="dashboard">
      <h1>Dashboard</h1>
      <p>Bienvenido, {user?.username}!</p>
      
      <div className="stats-grid">
        <div className="stat-card total">
          <h3>Total Tickets</h3>
          <p className="stat-number">{stats.total}</p>
        </div>
        <div className="stat-card open">
          <h3>Abiertos</h3>
          <p className="stat-number">{stats.open}</p>
        </div>
        <div className="stat-card progress">
          <h3>En Progreso</h3>
          <p className="stat-number">{stats.inProgress}</p>
        </div>
        <div className="stat-card closed">
          <h3>Cerrados</h3>
          <p className="stat-number">{stats.closed}</p>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
EOF

cat > src/pages/Tickets.jsx << 'EOF'
import React, { useState } from 'react';
import { useTickets } from '../hooks/useTickets';

const Tickets = () => {
  const { tickets, loading, error, createTicket, deleteTicket } = useTickets();
  const [showCreateForm, setShowCreateForm] = useState(false);
  const [newTicket, setNewTicket] = useState({
    title: '',
    description: '',
    priority: 'MEDIUM'
  });

  const handleCreateTicket = async (e) => {
    e.preventDefault();
    const result = await createTicket(newTicket);
    if (result.success) {
      setShowCreateForm(false);
      setNewTicket({ title: '', description: '', priority: 'MEDIUM' });
    }
  };

  const handleDelete = async (id) => {
    if (window.confirm('¿Estás seguro de eliminar este ticket?')) {
      await deleteTicket(id);
    }
  };

  if (loading) return <div className="loading">Cargando tickets...</div>;
  if (error) return <div className="error">Error: {error}</div>;

  return (
    <div className="tickets-page">
      <div className="page-header">
        <h1>Gestión de Tickets</h1>
        <button 
          className="btn-primary"
          onClick={() => setShowCreateForm(true)}
        >
          + Nuevo Ticket
        </button>
      </div>

      {showCreateForm && (
        <div className="modal-overlay">
          <div className="modal">
            <h3>Crear Nuevo Ticket</h3>
            <form onSubmit={handleCreateTicket}>
              <div className="form-group">
                <input
                  type="text"
                  placeholder="Título"
                  value={newTicket.title}
                  onChange={(e) => setNewTicket({...newTicket, title: e.target.value})}
                  required
                />
              </div>
              <div className="form-group">
                <textarea
                  placeholder="Descripción"
                  value={newTicket.description}
                  onChange={(e) => setNewTicket({...newTicket, description: e.target.value})}
                  required
                />
              </div>
              <div className="form-group">
                <select
                  value={newTicket.priority}
                  onChange={(e) => setNewTicket({...newTicket, priority: e.target.value})}
                >
                  <option value="LOW">Baja</option>
                  <option value="MEDIUM">Media</option>
                  <option value="HIGH">Alta</option>
                </select>
              </div>
              <div className="form-actions">
                <button type="submit">Crear</button>
                <button type="button" onClick={() => setShowCreateForm(false)}>
                  Cancelar
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      <div className="tickets-list">
        {tickets.length === 0 ? (
          <p>No hay tickets creados.</p>
        ) : (
          tickets.map(ticket => (
            <div key={ticket.id} className="ticket-card">
              <h3>{ticket.title}</h3>
              <p>{ticket.description}</p>
              <div className="ticket-meta">
                <span className={`priority ${ticket.priority?.toLowerCase()}`}>
                  {ticket.priority}
                </span>
                <span className={`status ${ticket.status?.toLowerCase()}`}>
                  {ticket.status}
                </span>
                <button 
                  className="btn-danger"
                  onClick={() => handleDelete(ticket.id)}
                >
                  Eliminar
                </button>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
};

export default Tickets;
EOF

# 14. Estilos CSS
echo "🎨 Creando estilos..."
cat > src/index.css << 'EOF'
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',
    sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  background-color: #f5f5f5;
  color: #333;
}

code {
  font-family: source-code-pro, Menlo, Monaco, Consolas, 'Courier New',
    monospace;
}

.loading {
  text-align: center;
  padding: 2rem;
  font-size: 1.2rem;
}

.error {
  color: #d32f2f;
  background: #ffebee;
  padding: 1rem;
  border-radius: 4px;
  margin: 1rem 0;
}

.error-message {
  background: #ffebee;
  color: #d32f2f;
  padding: 0.75rem;
  border-radius: 4px;
  margin-bottom: 1rem;
  border-left: 4px solid #d32f2f;
}
EOF

cat > src/App.css << 'EOF'
/* Health Status */
.health-status {
  background: #fff;
  padding: 0.5rem 1rem;
  border-bottom: 1px solid #e0e0e0;
  display: flex;
  gap: 1rem;
  font-size: 0.875rem;
}

.status-item {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.status-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  display: inline-block;
}

/* Navbar */
.navbar {
  background: #1976d2;
  color: white;
  padding: 1rem 2rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.nav-brand a {
  color: white;
  text-decoration: none;
  font-size: 1.5rem;
  font-weight: bold;
}

.nav-links {
  display: flex;
  align-items: center;
  gap: 1.5rem;
}

.nav-links a {
  color: white;
  text-decoration: none;
  padding: 0.5rem 1rem;
  border-radius: 4px;
  transition: background-color 0.2s;
}

.nav-links a:hover {
  background: rgba(255,255,255,0.1);
}

.user-info {
  color: #e3f2fd;
}

.logout-btn {
  background: transparent;
  color: white;
  border: 1px solid rgba(255,255,255,0.3);
  padding: 0.5rem 1rem;
  border-radius: 4px;
  cursor: pointer;
  transition: all 0.2s;
}

.logout-btn:hover {
  background: rgba(255,255,255,0.1);
  border-color: rgba(255,255,255,0.5);
}

/* Main Content */
.main-content {
  padding: 2rem;
  max-width: 1200px;
  margin: 0 auto;
}

/* Login Page */
.login-page {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.login-container {
  background: white;
  padding: 2rem;
  border-radius: 8px;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
  width: 100%;
  max-width: 400px;
}

.login-container h2 {
  text-align: center;
  margin-bottom: 1.5rem;
  color: #333;
}

.form-group {
  margin-bottom: 1rem;
}

.form-group input,
.form-group textarea,
.form-group select {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 1rem;
}

.form-group input:focus,
.form-group textarea:focus,
.form-group select:focus {
  outline: none;
  border-color: #1976d2;
}

.login-container button {
  width: 100%;
  padding: 0.75rem;
  background: #1976d2;
  color: white;
  border: none;
  border-radius: 4px;
  font-size: 1rem;
  cursor: pointer;
  transition: background-color 0.2s;
}

.login-container button:hover:not(:disabled) {
  background: #1565c0;
}

.login-container button:disabled {
  background: #ccc;
  cursor: not-allowed;
}

.switch-mode {
  background: none;
  border: none;
  color: #1976d2;
  cursor: pointer;
  text-decoration: underline;
  margin-left: 0.5rem;
}

/* Dashboard */
.dashboard h1 {
  margin-bottom: 1rem;
  color: #333;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
  margin: 2rem 0;
}

.stat-card {
  background: white;
  padding: 1.5rem;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  text-align: center;
  border-left: 4px solid #1976d2;
}

.stat-card.total { border-left-color: #1976d2; }
.stat-card.open { border-left-color: #ff9800; }
.stat-card.progress { border-left-color: #2196f3; }
.stat-card.closed { border-left-color: #4caf50; }

.stat-number {
  font-size: 2rem;
  font-weight: bold;
  color: #333;
  margin: 0.5rem 0;
}

/* Tickets Page */
.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
}

.btn-primary {
  background: #1976d2;
  color: white;
  border: none;
  padding: 0.75rem 1.5rem;
  border-radius: 4px;
  cursor: pointer;
  font-size: 1rem;
  transition: background-color 0.2s;
}

.btn-primary:hover {
  background: #1565c0;
}

.btn-danger {
  background: #d32f2f;
  color: white;
  border: none;
  padding: 0.5rem 1rem;
  border-radius: 4px;
  cursor: pointer;
  font-size: 0.875rem;
}

.btn-danger:hover {
  background: #c62828;
}

/* Modal */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0,0,0,0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal {
  background: white;
  padding: 2rem;
  border-radius: 8px;
  width: 90%;
  max-width: 500px;
  max-height: 90vh;
  overflow-y: auto;
}

.modal h3 {
  margin-bottom: 1.5rem;
}

.form-actions {
  display: flex;
  gap: 1rem;
  margin-top: 1rem;
}

.form-actions button {
  flex: 1;
  padding: 0.75rem;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 1rem;
}

.form-actions button[type="submit"] {
  background: #1976d2;
  color: white;
}

.form-actions button[type="button"] {
  background: #f5f5f5;
  color: #333;
}

/* Tickets List */
.tickets-list {
  display: grid;
  gap: 1rem;
}

.ticket-card {
  background: white;
  padding: 1.5rem;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  border-left: 4px solid #1976d2;
}

.ticket-card h3 {
  margin-bottom: 0.5rem;
  color: #333;
}

.ticket-card p {
  color: #666;
  margin-bottom: 1rem;
}

.ticket-meta {
  display: flex;
  gap: 1rem;
  align-items: center;
}

.priority, .status {
  padding: 0.25rem 0.75rem;
  border-radius: 20px;
  font-size: 0.875rem;
  font-weight: 500;
}

.priority.low { background: #e8f5e8; color: #2e7d32; }
.priority.medium { background: #fff3e0; color: #ef6c00; }
.priority.high { background: #ffebee; color: #d32f2f; }

.status.open { background: #e3f2fd; color: #1976d2; }
.status.in_progress { background: #fff3e0; color: #ef6c00; }
.status.closed { background: #e8f5e8; color: #2e7d32; }

/* Responsive */
@media (max-width: 768px) {
  .navbar {
    padding: 1rem;
    flex-direction: column;
    gap: 1rem;
  }
  
  .nav-links {
    flex-wrap: wrap;
    justify-content: center;
  }
  
  .main-content {
    padding: 1rem;
  }
  
  .page-header {
    flex-direction: column;
    gap: 1rem;
    align-items: flex-start;
  }
  
  .stats-grid {
    grid-template-columns: 1fr;
  }
  
  .ticket-meta {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.5rem;
  }
}
EOF

# 15. Actualizar Dockerfile para Vite
echo "🐳 Actualizando Dockerfile para Vite..."
cat > Dockerfile << 'EOF'
# Build stage
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./
RUN npm ci

# Copy source code
COPY . .
RUN npm run build

# Production stage
FROM nginx:alpine

# Copy built app
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
EOF

# 16. Configuración de Nginx
echo "🌐 Configurando Nginx..."
cat > nginx.conf << 'EOF'
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;

    # GZIP compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml text/javascript;

    # Serve static files
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Health check
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

# 17. Crear archivos adicionales
echo "📋 Creando archivos adicionales..."
cat > .gitignore << 'EOF'
# Logs
logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pnpm-debug.log*
lerna-debug.log*

# Runtime data
pids
*.pid
*.seed
*.pid.lock

# Directory for instrumented libs generated by jscoverage/JSCover
lib-cov

# Coverage directory used by tools like istanbul
coverage
*.lcov

# nyc test coverage
.nyc_output

# Grunt intermediate storage (https://gruntjs.com/creating-plugins#storing-task-files)
.grunt

# Bower dependency directory (https://bower.io/)
bower_components

# node-waf configuration
.lock-wscript

# Compiled binary addons (https://nodejs.org/api/addons.html)
build/Release

# Dependency directories
node_modules/
jspm_packages/

# Snowpack dependency directory (https://snowpack.dev/)
web_modules/

# TypeScript cache
*.tsbuildinfo

# Optional npm cache directory
.npm

# Optional eslint cache
.eslintcache

# Microbundle cache
.rpt2_cache/
.rts2_cache_cjs/
.rts2_cache_es/
.rts2_cache_umd/

# Optional REPL history
.node_repl_history

# Output of 'npm pack'
*.tgz

# Yarn Integrity file
.yarn-integrity

# dotenv environment variables file
.env
.env.development.local
.env.test.local
.env.production.local
.env.local

# parcel-bundler cache (https://parceljs.org/)
.cache
.parcel-cache

# Next.js build output
.next

# Nuxt.js build / generate output
.nuxt
dist

# Gatsby files
.cache/
# Comment in the public line in if your project uses Gatsby and not Next.js
# https://nextjs.org/blog/next-9-1#public-directory-support
# public

# vuepress build output
.vuepress/dist

# Serverless directories
.serverless/

# FuseBox cache
.fusebox/

# DynamoDB Local files
.dynamodb/

# TernJS port file
.tern-port

# Stores VSCode versions used for testing VSCode extensions
.vscode-test

# yarn v2
.yarn/cache
.yarn/unplugged
.yarn/build-state.yml
.yarn/install-state.gz
.pnp.*

# Vite
dist/
dist-ssr/
*.local

# Backup files
*-backup/
backup/
EOF

cat > README.md << 'EOF'
# TicketBoard Frontend

Frontend moderno construido con Vite + React para el sistema de gestión de tickets.

## 🚀 Características

- ⚡ **Vite** - Build tool ultra rápido
- ⚛️ **React 18** - Última versión de React
- 🎨 **CSS Moderno** - Estilos responsive y modernos
- 🔐 **Autenticación JWT** - Login y registro
- 🎫 **Gestión de Tickets** - CRUD completo de tickets
- 🔍 **Health Checks** - Monitoreo del backend y base de datos
- 🐳 **Docker** - Contenerización lista para producción

## 🛠️ Desarrollo

```bash
# Instalar dependencias
npm install

# Ejecutar en desarrollo
npm run dev

# Build para producción
npm run build

# Preview del build
npm run preview
