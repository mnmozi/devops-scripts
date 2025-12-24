package main

import (
	"log"
	"os"

	mail "github.com/wneessen/go-mail"
)

func getEnv(key string) string {
	val := os.Getenv(key)
	if val == "" {
		log.Fatalf("Required environment variable %s is not set", key)
	}
	return val
}

func main() {
	smtpHost := getEnv("SMTP_HOST")
	smtpUser := getEnv("SMTP_USERNAME")
	smtpPass := getEnv("SMTP_PASSWORD")
	mailFrom := getEnv("MAIL_FROM")
	mailTo := getEnv("MAIL_TO")

	// Create mail client
	c, err := mail.NewClient(
		smtpHost,
		mail.WithPort(587),
		mail.WithSMTPAuth(mail.SMTPAuthLogin), // Explicitly use AUTH LOGIN
		mail.WithUsername(smtpUser),
		mail.WithPassword(smtpPass),
		mail.WithTLSPolicy(mail.TLSMandatory),
	)
	if err != nil {
		log.Fatalf("SMTP client error: %v", err)
	}

	// Create email message
	m := mail.NewMsg()
	if err := m.From(mailFrom); err != nil {
		log.Fatalf("From error: %v", err)
	}
	if err := m.To(mailTo); err != nil {
		log.Fatalf("To error: %v", err)
	}
	m.Subject("Hello from go-mail")
	m.SetBodyString(mail.TypeTextPlain, "This is a test email using go-mail and AUTH LOGIN")

	// Send email
	if err := c.DialAndSend(m); err != nil {
		log.Fatalf("Send error: %v", err)
	}

	log.Println("✅ Email sent successfully!")
}
