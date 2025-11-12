// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Partner;

enum 108 "IC Partner Inbox Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "File Location") { Caption = 'File Location'; }
    value(1; "Database") { Caption = 'Database'; }
    value(2; "Email") { Caption = 'Email'; }
    value(3; "No IC Transfer") { Caption = 'No IC Transfer'; }
}
