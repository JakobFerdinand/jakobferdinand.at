import { Handler } from '@netlify/functions'
import client from '@sendgrid/mail';

const {
  SENDGRID_API_KEY,
  TO_EMAIL,
  FROM_EMAIL
} = process.env;

export const handler: Handler = async (event, context) => {
  if (event.httpMethod !== "POST") {
    return { statusCode: 405, body: "Method Not Allowed" };
  }

  if (!SENDGRID_API_KEY) {
    return {
      statusCode: 400,
      body: JSON.stringify({
        message: 'SENDGRID_API_KEY not provided.'
      })
    };
  }
  if (!TO_EMAIL) {
    return {
      statusCode: 400,
      body: JSON.stringify({
        message: 'TO_EMAIL not provided.'
      })
    };
  }
  if (!FROM_EMAIL) {
    return {
      statusCode: 400,
      body: JSON.stringify({
        message: 'FROM_EMAIL not provided.'
      })
    };
  }
  if (!event.body) {
    return {
      statusCode: 400,
      body: JSON.stringify({
        message: 'No body was been provided.'
      })
    };
  }

  const { name, fromEmail, message } = JSON.parse(event.body);

  client.setApiKey(SENDGRID_API_KEY);

  const data = {
    to: TO_EMAIL,
    from: FROM_EMAIL,
    subject: `New message from ${name} (${fromEmail})`,
    html: message
  };

  try {
    await client.send(data);
    return {
      statusCode: 200,
      body: 'Message sent'
    };
  } catch (err) {
    console.log(err);
    return {
      statusCode: err.code,
      body: JSON.stringify({ errorMessage: err.message })
    };
  }
};
