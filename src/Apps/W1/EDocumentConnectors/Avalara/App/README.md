# Avalara E-Document Connector

## App Overview
The **Avalara E-Document Connector** is a Microsoft Business Central extension that acts as a bridge between Business Central's E-Document framework and the **Avalara** E-Invoicing and E-Reporting platform. It enables seamless exchange of electronic documents (e-invoices) by leveraging the standard **E-Document Core** module.

## Architecture
The application is designed as a connector within the Microsoft E-Document framework.

*   **Foundation**: Built on top of the `E-Document Core` extension.
*   **Integration Point**: Extends the `Service Integration V2` Enum, allowing "Avalara" to be selected as a service provider in standard E-Document Service setup.
*   **Pattern**: Implements the standard interfaces `IDocumentSender`, `IDocumentReceiver`, and `IDocumentResponseHandler` to handle the lifecycle of electronic documents.

## Key Components

### 1. Setup & Configuration
*   **Connection Setup**: The hub for configuration is the `Connection Setup` table and `Connection Setup Card`. This stores:
    *   **Authentication Details**: Client ID, Client Secret, and Token information.
    *   **Endpoints**: URLs for Authentication and API (supports both Production and Sandbox/Test environments).
    *   **Company Context**: Avalara Company ID and Name.
    *   **Mode**: Configurable `Avalara Send Mode` (Production, Test, Certification) which maps to the underlying connection behavior.

### 2. Authentication
*   **Authenticator Codeunit**: Manages the OAuth connection lifecycle. It handles:
    *   Storage of secrets (Client ID/Secret) in Isolated Storage.
    *   Token retrieval and refreshing.
    *   Automatic initialization of default API URLs.

### 3. Activation & Mandates
*   **Activation Logic**: The app includes specific logic (`Activation.Codeunit.al`) to parse and import configuration data from Avalara.
*   **Data Models**:
    *   `Activation Header`: Stores high-level activation status.
    *   `Activation Mandate`: Stores specific country or region mandates supported by the connected Avalara account.

### 4. Document Processing
*   **Avalara Document Management**: This codeunit (`AvalaraDocumentManagement.Codeunit.al`) is the core engine for payload integration. It handles:
    *   Converting Business Central data to the JSON/XML format required by Avalara.
    *   Handling attachments and file downloads.
    *   Processing API responses (success, error, pending).
*   **Integration Implementation**: The `Integration Impl.` codeunit acts as the facade for the E-Document Core, directing calls for Sending, Receiving, and Status Updates to the Avalara specific processing logic.

## Technical Architecture & Implementation Details

The core of the Avalara E-Document Connector is built on top of the Microsoft E-Document Framework interfaces.

### Object Model & Interfaces

#### Integration Implementation
The primary codeunit is `Integration Impl.` (ID 6372), which implements the following standard interfaces:
*   **`IDocumentSender`**: Handles the submission of documents to Avalara.
*   **`IDocumentResponseHandler`**: Manages the polling of asynchronous status updates.
*   **`IDocumentReceiver`**: Retrieves inbound documents from the Avalara network.

This codeunit acts as a facade, delegating the actual business logic to the `Processing` Codeunit (ID 6379), which encapsulates the specific Avalara API workflow.

#### Codeunit Architecture
*   **`Processing` (6379)**: The main engine. Orchestrates data flow, calls helper codeunits, and manages business rules (e.g., mandate validation).
*   **`Authenticator` (6374)**: Handles OAuth 2.0 authentication, token lifecycle, and secure storage.
*   **`Requests` (6376)**: A factory codeunit responsible for constructing HTTP requests, setting headers, and defining API endpoints.
*   **`Http Executor` (6377)**: Executes `HttpRequestMessage` objects, handles HTTP status codes (4xx, 5xx), and manages telemetry/logging.
*   **`Avalara Functions` (6800)**: Contains utility functions for file attachment management, media type retrieval, and JSON parsing helpers.

### Detailed Data Flow

#### The "Send" Operation
When a user posts a document (e.g., Sales Invoice) configured for Avalara:

1.  **Context & Validation**:
    *   `Integration Impl.` calls `Processing.SendEDocument`.
    *   The system validates that a valid `Activation Mandate` exists for the company and country combination, ensuring the account is "Activated" and not "Blocked".
2.  **Payload Construction**:
    *   **Metadata**: A JSON object is constructed containing `workflowId` (e.g., `avalara-einvoicing`), `dataFormat` (e.g., `ubl-invoice-2.1`), `countryCode`, and `mandate` (e.g., `DE-B2B-UBL`).
    *   **Data**: The actual UBL XML content is read from the `SendContext` (TempBlob).
3.  **Request Construction**:
    *   A `Multipart/Form-Data` request is built in `Requests.CreateSubmitDocumentRequest`.
    *   Part 1: `metadata` (JSON).
    *   Part 2: `data` (XML file content).
4.  **Transmission**:
    *   The request is POSTed to `https://api.avalara.com/einvoicing/documents`.
    *   Bearer Token is automatically injected by the `Authenticator`.
5.  **Response Processing**:
    *   On Success (HTTP 201), the response JSON is parsed to extract the `id` (Avalara Document ID).
    *   This ID is stamped on the `E-Document` record for future tracking.

#### The "Get Response" Operation (Polling)
Asynchronous processing is handled via `Processing.GetDocumentStatus`:

1.  The system calls `GET /einvoicing/documents/{id}/status` using the stored Avalara Document ID.
2.  The JSON response is parsed for the `status` field:
    *   **`Pending`**: Returns `false` to the framework, keeping the document in "In Progress".
    *   **`Complete`**: Returns `true`, moving the document to "Processed".
    *   **`Error`**: Logs specific error messages from the `events` array in the response directly to the E-Document Error Log and fails the operation.

### Authentication Mechanism

The connector uses the **OAuth 2.0 Client Credentials Flow**.

*   **Storage**: Client ID, Client Secret, and Access Tokens are stored in **Isolated Storage** (DataScope: Company).
*   **Reference**: References to these keys (Guids) are stored in the `Connection Setup` table.
*   **Token Refresh Strategy**:
    *   Tokens are cached in Isolated Storage.
    *   Before every request, `Authenticator.GetAccessToken` checks the `Token Expiry` time.
    *   If the token expires in < 60 seconds, a new token is requested from `https://identity.avalara.com` (or sandbox equivalent).
*   **Endpoints**:
    *   Production Auth: `https://identity.avalara.com`
    *   Sandbox Auth: `https://ai-sbx.avlr.sh`

### API Interaction

#### Endpoint Summary
All API calls include standard headers: `Authorization: Bearer [Token]`, `avalara-version`, and `X-Avalara-Client`.

| Operation | Method | Endpoint | Description |
| :--- | :--- | :--- | :--- |
| **Send Document** | POST | `/einvoicing/documents` | Multipart submission of metadata and XML. |
| **Check Status** | GET | `/einvoicing/documents/{id}/status` | Polls for processing results. |
| **Get Documents**| GET | `/einvoicing/documents` | Receives inbound documents (Recursive paging supported). |
| **Download** | GET | `/einvoicing/documents/{id}/$download` | Downloads the processed XML/PDF. |
| **Mandates** | GET | `/einvoicing/mandates` | Fetches supported countries and formats. |
| **Companies** | GET | `/scs/companies` | Validates connected company details. |

### Error Handling

The `Http Executor` codeunit centralizes all HTTP response handling:

*   **200/201 (Success)**: Logs telemetry and returns content.
*   **400 (Bad Request)**: Parses the response body to extract the specific `message` field from Avalara (e.g., validation errors) and throws a user-friendly error.
*   **401 (Unauthorized)**: Throws "Authentication credentials are not valid". Check Client Setup.
*   **500 (Internal Server Error)**: Generic error message.
*   **Retry Logic**: The current implementation relies on the standard Business Central job queue retry mechanisms for transient errors; explicit automatic retries for HTTP 5xx are not implemented at the socket level.

## Usage Guide & Setup

1.  **Installation**: Install the "E-Document Connector - Avalara" extension.
2.  **Connection Setup**:
    *   Navigate to the **Connection Setup** page.
    *   Enter your Avalara **Client ID** and **Client Secret**.
    *   Choose your environment (Sandbox/Production).
3.  **E-Document Service**:
    *   Create a new **E-Document Service** in Business Central.
    *   Set the **Service Integration** field to **Avalara**.
    *   This will link the service to the connection setup configured in step 2.
4.  **Workflows**: Configure standard E-Document workflows (e.g., for Sales Invoices) to use this Service.

## Testing Strategy
The application includes a robust test suite located in the `test/` folder.

*   **Integration Tests** (`IntegrationTests.Codeunit.al`): Covers End-to-End scenarios:
    *   **SubmitDocument**: Full flow from posting to 'Sent' status.
    *   **Error Handling**: Scenarios for pending responses, API errors, and service downtime.
    *   **Document Retrieval**: Testing `GetDocuments` and `DownloadDocument` flows.
*   **Unit Tests**: Focused tests for authentication logic and document transformation helpers (`AvalaraFunctions`).
*   **Mocking**: Uses mock response files (in `test/HttpResponseFiles/`) to mock Avalara API responses, ensuring tests are deterministic and do not require live API connectivity during standard test runs.

## Technical Details
*   **Publisher**: Microsoft
*   **Dependencies**:
    *   `E-Document Core` (Publisher: Microsoft)
*   **Extensibility**:
    *   **Enums**: Extends `Service Integration V2` and `Avalara Trans. Rule Type`.
    *   **Events**: Subscribes to `OnBeforeOpenServiceIntegrationSetupPage` to redirect users to the connector-specific setup.
