// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using System.Security.AccessControl;

table 132 "Incoming Document Approver"
{
    Caption = 'Incoming Document Approver';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "User ID"; Guid)
        {
            Caption = 'User ID';
            DataClassification = EndUserPseudonymousIdentifiers;
        }
    }

    keys
    {
        key(Key1; "User ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure SetIsApprover(var User: Record User; IsApprover: Boolean)
    var
        IncomingDocumentApprover: Record "Incoming Document Approver";
        WasApprover: Boolean;
    begin
        IncomingDocumentApprover.LockTable();
        WasApprover := IncomingDocumentApprover.Get(User."User Security ID");
        if WasApprover and not IsApprover then
            IncomingDocumentApprover.Delete();
        if not WasApprover and IsApprover then begin
            IncomingDocumentApprover."User ID" := User."User Security ID";
            IncomingDocumentApprover.Insert();
        end;
    end;
}

