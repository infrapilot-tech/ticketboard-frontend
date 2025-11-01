// In production (K8s), nginx proxies /api/* to backend
// In development, use localhost backend directly
const API_BASE_URL = process.env.NODE_ENV === 'production' 
  ? '/api' 
  : (process.env.REACT_APP_API_URL || 'http://localhost:3000');

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
