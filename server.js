import express from 'express';
import fetch from 'node-fetch';

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware para permitir solicitudes CORS
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');
  next();
});

// Ruta para obtener los live scores desde la API de football-data.org para la próxima semana
app.get('/api/:league/next-week-live-scores', async (req, res) => {
    const league = req.params.league;
    try {
      const today = new Date();
      const nextWeek = new Date(today.getFullYear(), today.getMonth(), today.getDate() + 7); // Obtener la fecha de hoy + 7 días para la próxima semana
      const formattedNextWeek = nextWeek.toISOString().split('T')[0]; // Formatear la fecha de la próxima semana en formato ISO
      const response = await fetch(`https://api.football-data.org/v2/competitions/${league}/matches?dateFrom=${today.toISOString().split('T')[0]}&dateTo=${formattedNextWeek}&status=SCHEDULED`, {
        headers: {
          'X-Auth-Token': '9431a7b3652a47bfb3bda5bc870f4b56', // Reemplaza 'TU_API_KEY' con tu propia clave API
        },
      });
      const data = await response.json();
      res.json(data);
    } catch (error) {
      console.error('Error fetching next week live scores:', error);
      res.status(500).json({ error: 'Error fetching next week live scores' });
    }
  });
  

// Ruta para obtener los resultados de los partidos acabados del día de hoy
app.get('/api/:league/results', async (req, res) => {
    const league = req.params.league;
    try {
      const today = new Date().toISOString().split('T')[0]; // Obtener la fecha actual en formato ISO
      const response = await fetch(`https://api.football-data.org/v2/competitions/${league}/matches?dateFrom=${today}&dateTo=${today}&status=FINISHED`, {
        headers: {
          'X-Auth-Token': '9431a7b3652a47bfb3bda5bc870f4b56', // Reemplaza 'TU_API_KEY' con tu propia clave API
        },
      });
      const data = await response.json();
      res.json(data);
    } catch (error) {
      console.error('Error fetching today\'s finished matches:', error);
      res.status(500).json({ error: 'Error fetching today\'s finished matches' });
    }
  });

// Iniciar el servidor
app.listen(PORT, () => {
  console.log(`Servidor intermedio escuchando en el puerto ${PORT}`);
});
