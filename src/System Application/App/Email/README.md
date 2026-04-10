Provides an API that lets you connect email accounts to Business Central so that people can send messages without having to open their email application. The email module consists of the following main entities:

### Email Account
An email account holds the information needed to send emails from Business Central.

### Email Address Lookup
Email address lookup suggests email addresses to the user for the To, Cc and Bcc fields, and the suggestions are based on the related records of the email.

### Email Connector
An email connector is an interface for creating and managing email accounts, and sending emails. Every email account belongs to an email connector.

### Email Scenario
Email scenarios are specific business processes that involve documents or notifications. Use scenarios to seamlessly integrate email accounts with business processes.

### Email Message
Payload for every email that is being composed or already has been sent.

### Email Outbox
Holds draft emails, and emails that were not successfully sent.

### Sent Email
Holds emails that have been sent.

