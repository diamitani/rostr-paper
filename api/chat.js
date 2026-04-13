export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  let body;
  try {
    body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
  } catch {
    return res.status(400).json({ error: 'Invalid JSON body' });
  }

  const { message, api_key, system } = body || {};

  if (!api_key?.trim()) {
    return res.status(400).json({ error: 'api_key is required' });
  }
  if (!message?.trim()) {
    return res.status(400).json({ error: 'message is required' });
  }

  try {
    const upstream = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': api_key.trim(),
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: 'claude-haiku-4-5-20251001',
        max_tokens: 2048,
        system: system || 'You are a helpful assistant.',
        messages: [{ role: 'user', content: message }],
      }),
    });

    const data = await upstream.json();

    if (!upstream.ok) {
      return res.status(upstream.status).json({
        error: data.error?.message || `Anthropic API error ${upstream.status}`,
      });
    }

    return res.status(200).json({
      text: data.content?.[0]?.text || '',
      model: data.model,
      usage: data.usage,
    });
  } catch (err) {
    return res.status(500).json({ error: String(err) });
  }
}
