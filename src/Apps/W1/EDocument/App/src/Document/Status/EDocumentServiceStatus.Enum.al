// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

enum 6106 "E-Document Service Status" implements IEDocumentStatus
{
    Extensible = true;
    AssignmentCompatibility = true;
    DefaultImplementation = IEDocumentStatus = "E-Doc In Progress Status";

    value(0; "Created") { Caption = 'Created'; }
    value(1; "Exported")
    {
        Caption = 'Exported';
        Implementation = IEDocumentStatus = "E-Doc Processed Status";
    }
    value(2; "Sending Error")
    {
        Caption = 'Sending error';
        Implementation = IEDocumentStatus = "E-Doc Error Status";
    }
    value(3; "Cancel Error")
    {
        Caption = 'Cancel error';
        Implementation = IEDocumentStatus = "E-Doc Error Status";
    }
    value(4; "Canceled")
    {
        Caption = 'Canceled';
        Implementation = IEDocumentStatus = "E-Doc Processed Status";
    }
    value(5; "Imported") { Caption = 'Imported'; }
    value(6; "Imported Document Processing Error")
    {
        Caption = 'Imported document processing error';
        Implementation = IEDocumentStatus = "E-Doc Error Status";
    }
    value(7; "Imported Document Created")
    {
        Caption = 'Imported document created';
        Implementation = IEDocumentStatus = "E-Doc Processed Status";
    }
    value(8; "Order Updated") { Caption = 'Order updated'; }
    value(9; "Journal Line Created")
    {
        Caption = 'Journal line created';
        Implementation = IEDocumentStatus = "E-Doc Processed Status";
    }
    value(10; "Pending Batch") { Caption = 'Pending batch'; }
    value(11; "Export Error")
    {
        Caption = 'Export error';
        Implementation = IEDocumentStatus = "E-Doc Error Status";
    }
    value(12; "Pending Response") { Caption = 'Pending response'; }
    value(13; "Sent")
    {
        Caption = 'Sent';
        Implementation = IEDocumentStatus = "E-Doc Processed Status";
    }
    value(14; "Approved")
    {
        Caption = 'Approved';
        Implementation = IEDocumentStatus = "E-Doc Processed Status";
    }
    value(15; "Rejected")
    {
        Caption = 'Rejected';
        Implementation = IEDocumentStatus = "E-Doc Processed Status";
    }
    value(16; "Batch Imported") { Caption = 'Batch imported'; }
    value(17; "Order Linked") { Caption = 'Order linked'; }
    value(18; "Pending") { Caption = 'Pending document link'; }
    value(19; "Approval Error")
    {
        Caption = 'Approval error';
        Implementation = IEDocumentStatus = "E-Doc Error Status";
    }

    #region clearance model 30 - 40
    value(30; "Not Cleared")
    {
        Caption = 'Not Cleared';
    }
    value(31; "Cleared")
    {
        Caption = 'Cleared';
        Implementation = IEDocumentStatus = "E-Doc Processed Status";
    }
    #endregion

    #region V3 role-paired statuses driven by E-Document Messages
    // Status names describe who acted on the parent document, not who we are. This keeps the
    // values direction-neutral: a status reads correctly whether we are the sender or the
    // receiver of the parent. Receiver-driven statuses come from buyer-side messages
    // (PEPPOL Invoice Response, FR Refused, etc.); Sender-driven from seller-side
    // (FR Collected, MX Payment Complement acknowledged, etc.).
    value(40; "Receiver Acknowledged") { Caption = 'Receiver Acknowledged'; }
    value(41; "Receiver Processing") { Caption = 'Receiver Processing'; }
    value(42; "Receiver Under Query") { Caption = 'Receiver Under Query'; }
    value(43; "Receiver Conditionally Accepted") { Caption = 'Receiver Conditionally Accepted'; }
    value(44; "Receiver Accepted")
    {
        Caption = 'Receiver Accepted';
        Implementation = IEDocumentStatus = "E-Doc Processed Status";
    }
    value(45; "Receiver Accepted with Changes")
    {
        Caption = 'Receiver Accepted with Changes';
        Implementation = IEDocumentStatus = "E-Doc Processed Status";
    }
    value(46; "Receiver Rejected")
    {
        Caption = 'Receiver Rejected';
        Implementation = IEDocumentStatus = "E-Doc Error Status";
    }
    value(47; "Receiver Rejected (Validation)")
    {
        Caption = 'Receiver Rejected (Validation)';
        Implementation = IEDocumentStatus = "E-Doc Error Status";
    }
    value(48; "Receiver Paid")
    {
        Caption = 'Receiver Paid';
        Implementation = IEDocumentStatus = "E-Doc Processed Status";
    }
    value(49; "Sender Acknowledged") { Caption = 'Sender Acknowledged'; }
    value(50; "Sender Paid")
    {
        Caption = 'Sender Paid';
        Implementation = IEDocumentStatus = "E-Doc Processed Status";
    }
    value(51; "Sender Payment Reversed") { Caption = 'Sender Payment Reversed'; }
    #endregion
}
