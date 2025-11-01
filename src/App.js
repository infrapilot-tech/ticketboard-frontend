import React, { useEffect, useState } from "react";
import { getTickets, createTicket } from "./api";

function App() {
  const [tickets, setTickets] = useState([]);
  const [title, setTitle] = useState("");

  const fetchTickets = async () => {
    const data = await getTickets();
    setTickets(data);
  };

  const handleAdd = async () => {
    if (!title.trim()) return;
    await createTicket(title);
    setTitle("");
    fetchTickets();
  };

  useEffect(() => {
    fetchTickets();
  }, []);

  return (
    <div style={{ padding: "2rem", fontFamily: "Arial" }}>
      <h1>🎟️ TicketBoard</h1>

      <div style={{ marginBottom: "1rem" }}>
        <input
          type="text"
          placeholder="New ticket title..."
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          style={{ padding: "0.5rem" }}
        />
        <button
          onClick={handleAdd}
          style={{ marginLeft: "0.5rem", padding: "0.5rem 1rem" }}
        >
          Add
        </button>
      </div>

      <ul>
        {tickets.map((t) => (
          <li key={t.id}>
            #{t.id} - {t.title} ({t.status})
          </li>
        ))}
      </ul>
    </div>
  );
}

export default App;

