// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.EServices.EDocument.Interfactura;

using Microsoft.eServices.EDocument;

permissionset 3352 "E-Documents MX User"
{
    Assignable = true;
    IncludedPermissionSets = "E-Doc. Core - User";
    Caption = 'E-Documents MX - User';
    Permissions =
        table "MX Connection Setup" = X,
        tabledata "MX Connection Setup" = R,
        table "MX PAC Web Service Detail" = X,
        tabledata "MX PAC Web Service Detail" = R,
        table "MX Payment Complement" = X,
        tabledata "MX Payment Complement" = R,
        codeunit "EDoc CFDI MX" = X,
        codeunit "MX Interfactura Impl." = X,
        codeunit "Export Interfactura MX" = X,
        codeunit "Interfactura Processing" = X,
        codeunit "MX Payment Complement Builder" = X,
        codeunit "MX Payment Complement Mgt." = X,
        codeunit "MX Payment Response Mgt." = X,
        codeunit "MX Payment Compl. Dispatcher" = X,
        codeunit "MX Payment Compl. Cancel" = X,
        codeunit "Digital Sign MX" = X,
        codeunit "CFDI Cancellation MX" = X,
        codeunit "CFDI Write-Back MX" = X,
        codeunit "CFDI XML Helper MX" = X,
        codeunit "EDoc Carta Porte Validation MX" = X,
        codeunit "EDoc CFDI Validation MX" = X,
        codeunit "EDoc CFDI Print MX" = X,
        codeunit "EDoc CFDI Import MX" = X,
        codeunit "EDoc CFDI Read Draft MX" = X,
        codeunit "EDoc CFDI Email MX" = X,
        page "Interfactura Connection Setup" = X,
        page "MX PAC Web Service Details" = X,
        page "MX PAC WS Detail Edit Dlg" = X,
        page "MX CFDI Cancel Reason Dlg" = X,
        page "E-Doc. Payment Occurrences MX" = X,
        page "MX Payment Complements" = X,
        page "SAT Transport Types MX" = X,
        page "SAT ISTMO Regions MX" = X,
        report "EDoc CFDI Sales Invoice MX" = X,
        report "EDoc CFDI Sales Credit Memo MX" = X,
        report "EDoc CFDI Carta Porte MX" = X,
        report "EDoc CFDI Service Invoice MX" = X,
        report "EDoc CFDI Service Cr. Memo MX" = X,
        table "SAT Transport Type MX" = X,
        tabledata "SAT Transport Type MX" = RIMD,
        table "SAT ISTMO Region MX" = X,
        tabledata "SAT ISTMO Region MX" = RIMD,
        codeunit "Carta Porte Fields Copy MX" = X,
        codeunit "EDoc CFDI Data MX" = X,
        page "E-Doc. CFDI Data MX" = X,
        tabledata "CFDI Transport Operator" = RIMD;
}