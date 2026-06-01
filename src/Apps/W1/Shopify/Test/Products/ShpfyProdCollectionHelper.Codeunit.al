// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

codeunit 139553 "Shpfy Prod. Collection Helper"
{
    internal procedure GetProductCollectionResponse(Collection1Id: BigInteger): JsonArray
    var
        JPublications: JsonArray;
        NodesTxt: Text;
        ResInStream: InStream;
    begin
        NavApp.GetResource('Products/DefaultProductCollectionResponse.txt', ResInStream, TextEncoding::UTF8);
        ResInStream.ReadText(NodesTxt);
        JPublications.ReadFrom(StrSubstNo(NodesTxt, Collection1Id));
        exit(JPublications);
    end;
}