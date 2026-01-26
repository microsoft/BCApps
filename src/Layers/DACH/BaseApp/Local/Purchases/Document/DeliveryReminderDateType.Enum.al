// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

enum 5005272 "Delivery Reminder Date Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Requested Receipt Date") { Caption = 'Requested Receipt Date'; }
    value(2; "Promised Receipt Date") { Caption = 'Promised Receipt Date'; }
    value(3; "Expected Receipt Date") { Caption = 'Expected Receipt Date'; }
}
