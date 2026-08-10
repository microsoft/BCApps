// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 7225 "EA Corp Card Validate Mgt"
{
    Access = Internal;

    var
        MissingProviderCodeErr: Label 'Provider Code is missing.';
        MissingCardIdErr: Label 'Card Id is missing.';
        MissingProviderTransIdErr: Label 'Provider Trans Id is missing.';
        MissingTransDateErr: Label 'Trans Date is missing.';

    internal procedure ValidateTrans(var CorpCardTrans: Record "EA Corp Card Trans"): Boolean
    var
        ValidationReason: Text[250];
    begin
        exit(ValidateTrans(CorpCardTrans, ValidationReason));
    end;

    internal procedure ValidateTrans(var CorpCardTrans: Record "EA Corp Card Trans"; var ValidationReason: Text[250]): Boolean
    begin
        if CorpCardTrans."Provider Code" = '' then begin
            ValidationReason := MissingProviderCodeErr;
            exit(false);
        end;
        if CorpCardTrans."Card Id" = '' then begin
            ValidationReason := MissingCardIdErr;
            exit(false);
        end;
        if CorpCardTrans."Provider Trans Id" = '' then begin
            ValidationReason := MissingProviderTransIdErr;
            exit(false);
        end;
        if CorpCardTrans."Trans Date" = 0D then begin
            ValidationReason := MissingTransDateErr;
            exit(false);
        end;

        ValidationReason := '';

        exit(true);
    end;
}