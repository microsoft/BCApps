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
        page "Payment Occurrences" = X,
        page "MX CFDI Cancel Reason Dlg" = X,
        report "EDoc CFDI Sales Invoice MX" = X,
        report "EDoc CFDI Sales Credit Memo MX" = X,
        report "EDoc CFDI Carta Porte MX" = X;
}
