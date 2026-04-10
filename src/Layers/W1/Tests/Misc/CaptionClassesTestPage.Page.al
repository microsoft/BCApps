page 138695 "Caption Classes Test Page"
{
    PageType = Card;

    layout
    {
        area(Content)
        {
            field(ResolvedGlobalDim; TextValue)
            {
                CaptionClass = '1,1,1'; // supported Global Dim 1
            }
            field(UnresolvedGlobalDim; TextValue)
            {
                CaptionClass = '1,1,3'; // unsupported Global Dim 3
            }
            field(ResolvedShortcutDim; TextValue)
            {
                CaptionClass = '1,2,3'; // supported Shortcut Dim 3
            }
            field(UnresolvedShortcutDim; TextValue)
            {
                CaptionClass = '1,2,9'; // unsupported Shortcut Dim 9
            }
            field(ResolvedFilterGlobalDim; TextValue)
            {
                CaptionClass = '1,3,2'; // supported filter Global Dim 2
            }
            field(UnresolvedFilterGlobalDim; TextValue)
            {
                CaptionClass = '1,3,3'; // unsupported filter Global Dim 3
            }
            field(ResolvedFilterShortcutDim; TextValue)
            {
                CaptionClass = '1,4,3'; // supported filter Shortcut Dim 3
            }
            field(UnresolvedFilterShortcutDim; TextValue)
            {
                CaptionClass = '1,4,9'; // unsupported filter Shortcut Dim 9
            }
            field(ResolvedCodeCaptionDim; TextValue)
            {
                CaptionClass = '1,5,DIM'; // supported DIM with translation
            }
            field(ResolvedFilterCaptionDim; TextValue)
            {
                CaptionClass = '1,6,,DIM'; // supported filter DIM with translation
            }
            field(ResolvedShortcutDimName; TextValue)
            {
                CaptionClass = '1,7,3'; // supported Shortcut Dim 3
            }
            field(UnresolvedDim; TextValue)
            {
                CaptionClass = '1,8'; // '1,8' is not supported
            }
            field(ResolvedCurrency; TextValue)
            {
                CaptionClass = '101,1,Amount (%1)'; // supported as long LCY description
            }
            field(UnresolvedCurrency; TextValue)
            {
                CaptionClass = '101,4,Amount (%1)'; // '101,4' is not supported
            }
            field(ResolvedInclVAT; TextValue)
            {
                CaptionClass = '2,1,Amount'; // + incl. VAT
            }
            field(ResolvedExclVAT; TextValue)
            {
                CaptionClass = '2,0,Amount'; // + excl. VAT
            }
            field(UnresolvedVAT; TextValue)
            {
                CaptionClass = '2,2,Amount'; // '2,2' is not supported
            }
            field(UnresolvedCaptionArea; TextValue)
            {
                CaptionClass = '3,1'; // '3,1' is not supported
            }
            field(EmptyCountry; TextValue)
            {
                CaptionClass = '5,1,'; // Country code is blank
            }
            field(EmptyCounty; TextValue)
            {
                CaptionClass = '5,1,BLANK'; // County Name is blank in "Country/Region" 'BLANK'
            }
            field(UnresolvedCounty; TextValue)
            {
                CaptionClass = '5,122,XX'; // '5,122,' is not supported
            }
            field(MissingCommaCounty; TextValue)
            {
                CaptionClass = '52'; // Missing comma is not supported
            }
            field(ResolvedCounty; TextValue)
            {
                CaptionClass = '5,1,XX'; // County Name is filled in "Country/Region" 'XX'
            }
            field(ResolvedItemTracking; TextValue)
            {
                CaptionClass = '6,1'; // valid code
            }
            field(UnresolvedItemTracking; TextValue)
            {
                CaptionClass = '6,0'; // '6,0' is not supported
            }
        }
    }

    var
        TextValue: Text[30];

}