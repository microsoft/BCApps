// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

using System.Reflection;

interface "No. Series Cop. Field Search"
{
    Access = Internal;

    /// <summary>
    /// Finds the fields that are relevant to the entities from the user request.
    /// </summary>
    /// <param name="Entities">The entities extracted from the user request.</param>
    /// <param name="TempFieldToSearchIn">The fields to search in; only these fields can be found.</param>
    /// <param name="TempSearchResult">The found fields are added to this buffer with the original similarity of the method and the similarity normalized to 0..1 between the method's own bounds; fields already in it are kept.</param>
    procedure Search(Entities: List of [Text]; var TempFieldToSearchIn: Record "Field" temporary; var TempSearchResult: Record "No. Series Cop. Search Result" temporary);
}
