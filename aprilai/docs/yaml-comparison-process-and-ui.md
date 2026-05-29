# YAML Comparison (2+ Files) - Process and UI Design

## 1) Objective

Provide a fast, understandable way to compare two or more similar YAML files and surface differences by key path (for example `service.image.tag`), including:

- Missing keys
- Value differences
- Type differences
- Optional array order differences

The design must scale from 2 files to N files while keeping the output readable.

---

## 2) User Outcomes

1. Upload or paste 2+ YAML files.
2. Choose a baseline file (optional but recommended).
3. See a summary of how many keys match or differ.
4. Drill down by namespace/key path and inspect per-file values.
5. Filter to only important changes (for example only missing keys).
6. Export results (JSON/CSV) for audit or code review.

---

## 3) Comparison Process

## Step A: Ingest

- Accept files from upload, drag-and-drop, or paste text.
- Assign each file a display name and stable internal ID.
- Enforce minimum of 2 files.

## Step B: Parse + Validate

- Parse each YAML into a generic object tree.
- If a file fails to parse, keep it in the session but mark it `parse_error`.
- Allow comparison to proceed only with successfully parsed files.

## Step C: Normalize

Normalize all parsed trees into a consistent representation:

- Resolve YAML aliases/anchors where possible.
- Convert all maps to deterministic key order.
- Convert scalars to typed values (`string`, `number`, `bool`, `null`).
- Represent arrays as either:
  - Ordered lists (default), or
  - Canonicalized sets (optional "ignore array order").
- Flatten nested structures into dotted key paths:
  - Example: `service.ports[0].targetPort`.

## Step D: Build Key Universe

- Build the union of all key paths across all valid files.
- For each key path, collect each file's value (or `MISSING` sentinel).

## Step E: Diff Classification

For each key path, classify status:

- `MATCH`: all present values equivalent.
- `MISSING`: one or more files missing key.
- `TYPE_MISMATCH`: value types differ (`string` vs `number`).
- `VALUE_MISMATCH`: same type, different value.
- `ARRAY_ORDER_MISMATCH`: same members, different order (if order-sensitive mode).

For multi-file sessions, compute:

- `distinctValueCount`: number of unique normalized values.
- `filesWithMostCommonValue`: files matching the modal value.
- `outlierFiles`: files diverging from modal value.

## Step F: Group + Summarize

Roll up diff counts by top-level namespace:

- `service.*`
- `database.*`
- `logging.*`

Generate summary metrics:

- Total key paths
- Matched key paths
- Differing key paths
- Missing keys
- Parse errors

## Step G: Present + Export

- Render namespace tree and detailed per-key diff table.
- Support CSV/JSON export with one row per key path and one column per file value.

---

## 4) Data Model (Implementation-Oriented)

```text
ComparisonSession
  files: List<YamlFile>
  options: ComparisonOptions
  summary: DiffSummary
  rows: List<DiffRow>

YamlFile
  id: String
  name: String
  sourceType: upload | paste
  rawText: String
  parseError: String?

ComparisonOptions
  baselineFileId: String?
  ignoreArrayOrder: bool
  ignoreWhitespaceInStrings: bool
  treatNullAndMissingAsEqual: bool

DiffRow
  keyPath: String
  namespace: String
  status: match | missing | typeMismatch | valueMismatch | arrayOrderMismatch
  valuesByFileId: Map<String, NormalizedValueOrMissing>
  distinctValueCount: int
```

---

## 5) UI Design

## A. Screen Flow

1. **Compare Setup**
   - Add files (2+)
   - Validate parse status
   - Select options and baseline
   - Action: `Compare`

2. **Comparison Results**
   - Top summary bar (metrics + status chips)
   - Left pane namespace/key tree
   - Main pane key diff table
   - Right drawer key details (optional)

## B. Setup Screen Layout

```text
+--------------------------------------------------------------+
| Compare YAML Files                                           |
| [Upload Files] [Paste YAML]                                 |
|--------------------------------------------------------------|
| Files                                                        |
| 1) values-dev.yaml      Parsed                              |
| 2) values-staging.yaml  Parsed                              |
| 3) values-prod.yaml     Parsed                              |
|                                                              |
| Baseline: (o) values-dev.yaml  ( ) values-staging.yaml ...  |
|                                                              |
| Options:                                                     |
| [x] Ignore array order                                       |
| [ ] Ignore whitespace differences                            |
| [ ] Treat null == missing                                    |
|                                                              |
|                                 [Cancel] [Compare]           |
+--------------------------------------------------------------+
```

## C. Results Screen Layout

```text
+--------------------------------------------------------------------------------+
| YAML Comparison: dev vs staging vs prod                                        |
| Total Keys: 428 | Differences: 37 | Missing: 12 | Type Mismatch: 3             |
| Filters: [All] [Differences] [Missing] [Type] [Search key path...........]     |
|--------------------------------------------------------------------------------|
| Namespaces              | Key Path                    | dev | staging | prod    |
|-------------------------+-----------------------------+-----+---------+---------|
| service (12)            | service.image.tag           |1.4.2|1.4.2    |1.5.0 !  |
| service (12)            | service.replicas            |2    |2        |4 !      |
| database (8)            | database.ssl.enabled        |true |MISSING !|true     |
| logging (5)             | logging.level               |info |debug !  |info     |
| ...                                                                         ... |
|--------------------------------------------------------------------------------|
| Detail (selected key): service.image.tag                                       |
| Type: string | Status: VALUE_MISMATCH | Distinct Values: 2                     |
| Raw values: dev=1.4.2, staging=1.4.2, prod=1.5.0                               |
+--------------------------------------------------------------------------------+
```

## D. Interaction Patterns

- Click a namespace to filter table rows.
- Click a row to open key detail drawer.
- Toggle "Show only differences" for focused review.
- Search by key path or value substring.
- Sticky header and pinned key column for large tables.
- Horizontal scroll for many files, with baseline column pinned.

## E. Color + Status Tokens

- `MATCH`: neutral/green
- `VALUE_MISMATCH`: amber
- `MISSING`: red
- `TYPE_MISMATCH`: purple
- `ARRAY_ORDER_MISMATCH`: blue

Use icon + text (not color-only) for accessibility.

---

## 6) Multi-File Comparison Rules

When comparing more than 2 files:

1. **Primary row status**:
   - `MATCH` only when all files equivalent.
   - Otherwise classify by highest-severity condition:
     `TYPE_MISMATCH > MISSING > VALUE_MISMATCH > ARRAY_ORDER_MISMATCH`.

2. **Baseline-aware indicators**:
   - Show whether each non-baseline file matches baseline.
   - Keep "majority value" hint for fast triage.

3. **Scalability safeguards**:
   - Default collapsed namespaces.
   - Virtualized table rendering for large key counts.
   - Optional per-namespace loading for very large YAMLs.

---

## 7) Edge Cases

- Duplicate keys in YAML source: report parser warning.
- Anchors/aliases not resolvable: show warning and compare resolved subset.
- Mixed object/list types at same path across files: `TYPE_MISMATCH`.
- Large files (>5 MB): show progress indicator and move compare work off UI thread.

---

## 8) Suggested Flutter Component Breakdown

- `YamlCompareSetupScreen`
  - `YamlFilePickerCard`
  - `YamlFileList`
  - `ComparisonOptionsPanel`
- `YamlCompareResultsScreen`
  - `DiffSummaryBar`
  - `NamespaceTreePanel`
  - `DiffTable`
  - `DiffDetailDrawer`
- `YamlComparisonController` (state management)
- `YamlDiffEngine` (pure compare logic)

State recommendation: use immutable view models (`freezed` style) and isolate compare logic in a testable service.

---

## 9) Test Strategy

1. Unit tests for `YamlDiffEngine`:
   - Missing key detection
   - Type mismatch detection
   - Multi-file mismatch grouping
   - Array order ignore/sensitive toggles

2. Widget tests:
   - Setup validation (requires 2+ parsed files)
   - Filter chips change visible rows
   - Selecting row updates detail drawer

3. Performance test:
   - 3 files x 2000 key paths should remain interactive with virtualized list.

---

## 10) Future Extensions

- Three-way merge assistance (propose merged YAML).
- Side-by-side raw YAML with synchronized scroll and key highlighting.
- Severity policies (custom rules for "critical keys").
- Git-aware mode (compare YAML across branches or commits).
