// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;
using System;

codeunit 3112 "Activity Log Builder Impl."
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;

    var
        LogEntry: DotNet ActivityLogEntry;
        AttributeType: DotNet ActivityLogAttribute;
        GlobalFieldNo: Integer;

    procedure Init(TableNo: Integer; FieldNo: Integer; RecSystemId: Guid): Codeunit "Activity Log Builder Impl."
    begin
        Clear(LogEntry);
        LogEntry := LogEntry.Create(TableNo, RecSystemId);
        this.GlobalFieldNo := FieldNo;
        exit(this);
    end;

    procedure SetExplanation(Explanation: Text): Codeunit "Activity Log Builder Impl."
    begin
        LogEntry.AddFieldAttribute(this.GlobalFieldNo, AttributeType::Explanation, Explanation);
        exit(this);
    end;

    procedure SetReferenceSource(PageId: Integer; var Rec: RecordRef): Codeunit "Activity Log Builder Impl."
    var
        TextURL: Text;
    begin
        TextURL := System.GetUrl(CurrentClientType(), CompanyName(), ObjectType::Page, PageId, Rec, true);
        LogEntry.AddFieldAttribute(this.GlobalFieldNo, AttributeType::ReferenceSource, TextURL);
        exit(this);
    end;

    procedure SetReferenceSource(ReferenceSource: Text): Codeunit "Activity Log Builder Impl."
    begin
        LogEntry.AddFieldAttribute(this.GlobalFieldNo, AttributeType::ReferenceSource, ReferenceSource);
        exit(this);
    end;

    procedure SetReferenceTitle(ReferenceTitle: Text): Codeunit "Activity Log Builder Impl."
    begin
        LogEntry.AddFieldAttribute(this.GlobalFieldNo, AttributeType::ReferenceTitle, ReferenceTitle);
        exit(this);
    end;

    procedure Log()
    begin
        LogEntry.Log();
    end;

}