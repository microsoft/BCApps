// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

/*
 UUID en la card del E-Document

→ Extender "E-Document" page
→ No agrega campos de tabla (UUID va en E-Doc Data Storage)
→ Agregar FactBox o campo calculado que muestre el Fiscal Invoice Number PAC
  leyendo desde el posted header via Document Record ID
→ Opcional: mostrar QR Code desde el posted header

*/

pageextension 3303 "CFDI E-Document" extends "E-Document"
{
}