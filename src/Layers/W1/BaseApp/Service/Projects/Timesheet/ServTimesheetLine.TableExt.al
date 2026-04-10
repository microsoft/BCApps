// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

using Microsoft.Service.Document;

tableextension 6464 "Serv. Time Sheet Line" extends "Time Sheet Line"
{
    fields
    {
        modify("Service Order No.")
        {
            TableRelation = if (Posted = const(false)) "Service Header"."No." where("Document Type" = const(Order));

            trigger OnBeforeValidate()
            var
                ServiceHeader: Record "Service Header";
            begin
                if "Service Order No." <> '' then begin
                    TestField(Type, Type::Service);
                    ServiceHeader.Get(ServiceHeader."Document Type"::Order, "Service Order No.");
                    Description := CopyStr(
                        StrSubstNo(DescriptionTxt, "Service Order No.", ServiceHeader."Customer No."),
                        1,
                        MaxStrLen(Description));
                end else
                    Description := '';
            end;
        }
    }

    var
        DescriptionTxt: Label 'Service order %1 for customer %2', Comment = '%1 - order number, %2 - customer number';
}
