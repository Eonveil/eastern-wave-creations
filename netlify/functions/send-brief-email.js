// Netlify Serverless Function to send an email via Resend when a new project brief is submitted.
// It retrieves the target recipient email dynamically from Supabase (ewc_secure.vault_config).

export const handler = async (event) => {
  // Only allow POST requests
  if (event.httpMethod !== 'POST') {
    return {
      statusCode: 405,
      body: JSON.stringify({ error: 'Method Not Allowed' })
    };
  }

  try {
    const brief = JSON.parse(event.body);
    if (!brief.name || !brief.email || !brief.service || !brief.message) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: 'Missing required brief details' })
      };
    }

    // 1. Retrieve connection parameters from Environment
    const resendApiKey = process.env.RESEND_API_KEY;
    const supabaseUrl = process.env.SUPABASE_DATABASE_URL || process.env.SUPABASE_URL || '';
    const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

    if (!resendApiKey) {
      console.error('RESEND_API_KEY is not defined in Netlify environment');
      return {
        statusCode: 500,
        body: JSON.stringify({ error: 'Mail server credentials not configured' })
      };
    }

    // 2. Fetch target recipient email from Supabase ewc_secure.vault_config
    let targetEmail = 'info@easternwavecreations.co.za'; // fallback default
    if (supabaseUrl && supabaseKey) {
      try {
        const dbRes = await fetch(`${supabaseUrl}/rest/v1/vault_config?id=eq.1`, {
          headers: {
            'apikey': supabaseKey,
            'Authorization': `Bearer ${supabaseKey}`,
            'Accept-Profile': 'ewc_secure'
          }
        });
        if (dbRes.ok) {
          const settings = await dbRes.json();
          if (settings && settings[0] && settings[0].email) {
            targetEmail = settings[0].email;
          }
        }
      } catch (dbErr) {
        console.error('Failed to query recipient email from Supabase, falling back to default:', dbErr);
      }
    }

    // 3. Map service code to readable name
    const serviceMap = {
      'headless-website': 'Headless Web Development',
      'whatsapp-automation': 'WhatsApp Automation',
      'both': 'Both Solutions Combined',
      'other': 'Other Inquiry'
    };
    const serviceName = serviceMap[brief.service] || brief.service;

    // 4. Construct beautiful HTML Email template (sleek dark mode matching EWC brand)
    const emailHtml = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>New Project Brief Submitted</title>
        <style>
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
            background-color: #030305;
            color: #f3f4f6;
            margin: 0;
            padding: 40px 20px;
          }
          .container {
            max-width: 600px;
            margin: 0 auto;
            background: #0c0d14;
            border: 1px solid #1f2937;
            border-radius: 12px;
            overflow: hidden;
            box-shadow: 0 10px 25px -5px rgba(0,0,0,0.5);
          }
          .header {
            background: linear-gradient(135deg, #0f172a 0%, #030712 100%);
            padding: 30px;
            text-align: center;
            border-bottom: 1px solid #1f2937;
          }
          .logo-text {
            font-size: 20px;
            font-weight: 800;
            letter-spacing: 0.05em;
            color: #ffffff;
            margin: 0;
          }
          .logo-wave {
            background: linear-gradient(135deg, #0ea5e9 0%, #06b6d4 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
          }
          .logo-accent {
            color: #9ca3af;
            font-weight: 400;
          }
          .content {
            padding: 40px 30px;
          }
          .title {
            font-size: 22px;
            font-weight: 700;
            color: #ffffff;
            margin-top: 0;
            margin-bottom: 24px;
            border-left: 3px solid #0ea5e9;
            padding-left: 12px;
          }
          .grid {
            display: table;
            width: 100%;
            margin-bottom: 24px;
          }
          .row {
            display: table-row;
          }
          .label {
            display: table-cell;
            width: 120px;
            padding: 8px 0;
            font-weight: 600;
            color: #9ca3af;
            font-size: 14px;
            vertical-align: top;
          }
          .value {
            display: table-cell;
            padding: 8px 0;
            color: #f3f4f6;
            font-size: 14px;
            vertical-align: top;
          }
          .brief-box {
            background: #11131e;
            border: 1px solid #23273e;
            border-radius: 8px;
            padding: 20px;
            margin-top: 10px;
            font-size: 14px;
            line-height: 1.6;
            color: #d1d5db;
            white-space: pre-wrap;
          }
          .footer {
            background: #030305;
            padding: 20px 30px;
            text-align: center;
            font-size: 12px;
            color: #6b7280;
            border-top: 1px solid #1f2937;
          }
          .footer a {
            color: #0ea5e9;
            text-decoration: none;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1 class="logo-text"><span class="logo-wave">Eastern</span> Wave <span class="logo-accent">Creations</span></h1>
          </div>
          <div class="content">
            <h2 class="title">New Client Inquiry</h2>
            <div class="grid">
              <div class="row">
                <div class="label">Name:</div>
                <div class="value"><strong>${brief.name}</strong></div>
              </div>
              <div class="row">
                <div class="label">Email:</div>
                <div class="value"><a href="mailto:${brief.email}" style="color: #0ea5e9; text-decoration: none;">${brief.email}</a></div>
              </div>
              <div class="row">
                <div class="label">Service:</div>
                <div class="value"><span style="background: rgba(14,165,233,0.1); color: #0ea5e9; border: 1px solid rgba(14,165,233,0.2); padding: 2px 8px; border-radius: 4px; font-size: 12px; font-weight: 600;">${serviceName}</span></div>
              </div>
            </div>
            
            <h3 style="font-size: 15px; font-weight: 600; color: #ffffff; margin-bottom: 8px; margin-top: 24px;">Project Brief Description:</h3>
            <div class="brief-box">${brief.message}</div>
          </div>
          <div class="footer">
            <p>This inquiry was collected dynamically from <a href="https://easternwavecreations.co.za">easternwavecreations.co.za</a>.</p>
          </div>
        </div>
      </body>
      </html>
    `;

    // 5. Send API request to Resend
    const mailRes = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${resendApiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        from: 'Eastern Wave Console <onboarding@resend.dev>',
        to: targetEmail,
        subject: `[New Inquiry] Project Brief from ${brief.name}`,
        html: emailHtml
      })
    });

    if (!mailRes.ok) {
      const errText = await mailRes.text();
      console.error(`Resend API request failed: ${errText}`);
      throw new Error(`Resend responded with status ${mailRes.status}`);
    }

    const mailResult = await mailRes.json();
    return {
      statusCode: 200,
      body: JSON.stringify({ message: 'Email sent successfully', id: mailResult.id })
    };

  } catch (error) {
    console.error('Serverless function execution crashed:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error.message || 'Internal Server Error' })
    };
  }
};
