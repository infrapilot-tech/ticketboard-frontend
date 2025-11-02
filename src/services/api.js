import axios from 'axios';

// Para Kubernetes - apunta al servicio del backend
// Para desarrollo local: crea un archivo .env con VITE_API_URL=http://localhost:3000
const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://backend-service:80';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 15000,
});

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

// Servicios básicos - solo los endpoints que tu backend tiene actualmente
export const ticketService = {
  getAllTickets: () => api.get('/tickets'),
  createTicket: (ticketData) => api.post('/tickets', ticketData),
  // Comenta estos hasta que los implementes en el backend:
  // getTicketById: (id) => api.get(`/tickets/${id}`),
  // updateTicket: (id, ticketData) => api.put(`/tickets/${id}`, ticketData),
  // deleteTicket: (id) => api.delete(`/tickets/${id}`),
  // searchTickets: (query) => api.get(`/tickets/search?q=${query}`),
};

export const authService = {
  // Comenta estos hasta que implementes auth en el backend:
  // login: (credentials) => api.post('/auth/login', credentials),
  // register: (userData) => api.post('/auth/register', userData),
  // verifyToken: () => api.get('/auth/verify'),
  logout: () => {
    localStorage.removeItem('authToken');
    return Promise.resolve();
  },
};

export const healthService = {
  checkBackend: () => api.get('/healthz'),
};

export default api;