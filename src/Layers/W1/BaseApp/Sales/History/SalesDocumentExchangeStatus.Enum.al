// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

/// <summary>
/// Defines the status values for electronic document exchange of sales documents.
/// </summary>
enum 711 "Sales Document Exchange Status"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Indicates that the document has not been sent to the document exchange service.
    /// </summary>
    value(0; "Not Sent") { Caption = 'Not Sent'; }
    /// <summary>
    /// Indicates that the document has been sent to the document exchange service for processing.
    /// </summary>
    value(1; "Sent to Document Exchange Service") { Caption = 'Sent to Document Exchange Service'; }
    /// <summary>
    /// Indicates that the document has been successfully delivered to the recipient.
    /// </summary>
    value(2; "Delivered to Recipient") { Caption = 'Delivered to Recipient'; }
    /// <summary>
    /// Indicates that delivery of the document to the recipient has failed.
    /// </summary>
    value(3; "Delivery Failed") { Caption = 'Delivery Failed'; }
    /// <summary>
    /// Indicates that the document is waiting for the recipient to establish a connection.
    /// </summary>
    value(4; "Pending Connection to Recipient") { Caption = 'Pending Connection to Recipient'; }
}
