# Search Vocabulary

BC domain phrases and stop words used by the regex-based keyword extraction fallback.
The triage agent loads these at runtime — edit here to adjust search term extraction behavior.

This vocabulary is only used when LLM-extracted search terms are unavailable (< 3 terms).
The LLM uses its own understanding of BC domain terminology for primary extraction.

## BC Domain Phrases

Multi-word Business Central terms that should be kept intact during extraction.
One phrase per line. Longer phrases should appear first (they are sorted by length at runtime).

```
purchase order
purchase invoice
purchase line
purchase header
sales order
sales invoice
sales line
sales header
sales price
general ledger
general journal
chart of accounts
bank reconciliation
bank account
fixed asset
fixed assets
posting group
posting groups
number series
no. series
dimension value
dimension set
item tracking
item charge
item journal
warehouse receipt
warehouse shipment
production order
production bom
bill of material
work center
machine center
service order
service item
service contract
service document
service documents
service management
service price
service line
approval workflow
approval entry
approval request
cash flow
cash flow forecast
cost accounting
cost center
cost type
assembly order
assembly bom
data archive
data search
data exchange
e-document
e-invoice
subscription billing
recurring billing
quality management
quality inspection
power bi
excel report
role center
ledger entry
customer ledger
vendor ledger
item ledger
job queue
job journal
payment journal
payment registration
intercompany
responsibility center
shopify connector
retention policy
price list
price calculation
transfer order
location transfer
human resource
employment contract
```

## Stop Words

Common words filtered out during regex-based keyword extraction.
These are excluded because they appear frequently but carry no search value.

### English stop words
```
the a an is are was were be been being
have has had do does did will would could
should may might can shall to of in for
on with at by from as into through during
before after above below between out off over
under again further then once here there when
where why how all each every both few more
most other some such no not only own same
so than too very and but or nor if it
this that these those i we you he she
they me us him her them my our your his
its their what which who whom about up
```

### Generic terms (too vague for search)
```
something anything everything nothing thing things
however therefore instead already currently actually
basically simply really always never sometimes
able unable possible impossible necessary specific
```

### AL language keywords (code, not business terms)
```
procedure var begin end local trigger true false
then else exit repeat until case with rec
text integer boolean decimal guid enum interface
try catch throw return call method parameter
```

### Generic software terms
```
item items page pages table tables field fields
function functions report reports codeunit codeunits
value values number numbers code name list card
document documents entry entries line lines record
records data type option action error issue bug
feature request add added adding change changed
new create update delete get set show display
open close run use used using work works
need want like make way also just still
appear appears look looks seem seems expected
log logging message result response context
init setup handler helper util utils
file files path string object class module
```
