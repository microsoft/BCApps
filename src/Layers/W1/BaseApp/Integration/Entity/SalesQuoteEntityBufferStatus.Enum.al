// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Entity;

#pragma warning disable AL0659
enum 5505 "Sales Quote Entity Buffer Status"
#pragma warning restore AL0659
{
    Extensible = false;
    AssignmentCompatibility = true;

    value(0; Draft)
    {
        Caption = 'Draft';
    }
    value(1; Sent)
    {
        Caption = 'Sent';
    }
    value(2; "Accepted")
    {
        Caption = 'Accepted';
    }
    value(3; "Expired ")
    {
    }
}