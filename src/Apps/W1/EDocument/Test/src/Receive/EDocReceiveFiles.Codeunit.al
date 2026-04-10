// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

codeunit 139635 "E-Doc. Receive Files"
{
    procedure GetDocument1(): Text
    begin
        exit(NavApp.GetResourceAsText('peppol/PEPPOL1.xml'));
    end;

}