import { useMemo, useState } from "react";
import yaml from "js-yaml";

const FILTERS = [
  { key: "all", label: "All" },
  { key: "differences", label: "Differences" },
  { key: "missing", label: "Missing" },
  { key: "typeMismatch", label: "Type Mismatch" },
  { key: "valueMismatch", label: "Value Mismatch" },
  { key: "arrayOrderMismatch", label: "Array Order" },
  { key: "match", label: "Match" },
];

function parseYamlText(rawText) {
  try {
    return { parsed: yaml.load(rawText), parseError: null };
  } catch (error) {
    return { parsed: null, parseError: error.message };
  }
}

function getValueType(value) {
  if (value === null) {
    return "null";
  }
  if (Array.isArray(value)) {
    return "array";
  }
  return typeof value === "object" ? "object" : typeof value;
}

function flattenYaml(node, keyPath = "", out = {}) {
  const type = getValueType(node);

  if (type === "array") {
    if (keyPath) {
      out[keyPath] = { type: "array", value: node };
    }
    node.forEach((item, index) => {
      flattenYaml(item, `${keyPath}[${index}]`, out);
    });
    return out;
  }

  if (type === "object") {
    const keys = Object.keys(node ?? {});
    if (keys.length === 0 && keyPath) {
      out[keyPath] = { type: "object", value: {} };
    }
    keys
      .sort((left, right) => left.localeCompare(right))
      .forEach((key) => {
        const nestedPath = keyPath ? `${keyPath}.${key}` : key;
        flattenYaml(node[key], nestedPath, out);
      });
    return out;
  }

  if (keyPath) {
    out[keyPath] = { type, value: node };
  }
  return out;
}

function normalizeValue(value, options, forceIgnoreArrayOrder = null) {
  const ignoreArrayOrder =
    forceIgnoreArrayOrder === null
      ? options.ignoreArrayOrder
      : forceIgnoreArrayOrder;

  if (value === null || typeof value === "number" || typeof value === "boolean") {
    return value;
  }

  if (typeof value === "string") {
    return options.ignoreWhitespaceInStrings ? value.trim() : value;
  }

  if (Array.isArray(value)) {
    const normalizedItems = value.map((item) =>
      normalizeValue(item, options, forceIgnoreArrayOrder),
    );
    if (!ignoreArrayOrder) {
      return normalizedItems;
    }
    return normalizedItems
      .slice()
      .sort((left, right) =>
        stableStringify(left).localeCompare(stableStringify(right)),
      );
  }

  const keys = Object.keys(value).sort((left, right) => left.localeCompare(right));
  const normalizedObject = {};
  keys.forEach((key) => {
    normalizedObject[key] = normalizeValue(
      value[key],
      options,
      forceIgnoreArrayOrder,
    );
  });
  return normalizedObject;
}

function stableStringify(value) {
  if (value === null || typeof value !== "object") {
    return JSON.stringify(value);
  }
  if (Array.isArray(value)) {
    return `[${value.map((item) => stableStringify(item)).join(",")}]`;
  }
  const keys = Object.keys(value).sort((left, right) => left.localeCompare(right));
  const pairs = keys.map((key) => `${JSON.stringify(key)}:${stableStringify(value[key])}`);
  return `{${pairs.join(",")}}`;
}

function getComparableValue(value, options, forceIgnoreArrayOrder = null) {
  return stableStringify(normalizeValue(value, options, forceIgnoreArrayOrder));
}

function formatValue(value) {
  if (value === null) {
    return "null";
  }
  if (typeof value === "string") {
    return value;
  }
  const serialized = JSON.stringify(value);
  if (serialized.length <= 80) {
    return serialized;
  }
  return `${serialized.slice(0, 77)}...`;
}

function getNamespace(keyPath) {
  const dotIndex = keyPath.indexOf(".");
  const bracketIndex = keyPath.indexOf("[");
  const candidateEndIndexes = [dotIndex, bracketIndex].filter((index) => index >= 0);
  if (candidateEndIndexes.length === 0) {
    return keyPath;
  }
  return keyPath.slice(0, Math.min(...candidateEndIndexes));
}

function classifyRow(path, files, mapByFileId, options) {
  const valuesByFileId = {};
  const presentEntries = [];
  let missingCount = 0;

  files.forEach((file) => {
    const entry = mapByFileId[file.id][path];
    if (!entry) {
      missingCount += 1;
      valuesByFileId[file.id] = {
        missing: true,
        type: "missing",
        raw: null,
        display: "MISSING",
      };
      return;
    }
    presentEntries.push({ fileId: file.id, ...entry });
    valuesByFileId[file.id] = {
      missing: false,
      type: entry.type,
      raw: entry.value,
      display: formatValue(entry.value),
      comparable: getComparableValue(entry.value, options),
    };
  });

  const allMissingOrNullEquivalent =
    options.treatNullAndMissingAsEqual &&
    missingCount > 0 &&
    presentEntries.every((entry) => entry.type === "null");

  const typeSet = new Set(presentEntries.map((entry) => entry.type));

  let status = "match";

  if (missingCount > 0 && !allMissingOrNullEquivalent) {
    status = "missing";
  } else if (typeSet.size > 1) {
    status = "typeMismatch";
  } else if (presentEntries.length > 1) {
    const orderedComparableSet = new Set(
      presentEntries.map((entry) => getComparableValue(entry.value, options, false)),
    );
    if (orderedComparableSet.size > 1) {
      const onlyType = presentEntries[0]?.type;
      if (onlyType === "array" && !options.ignoreArrayOrder) {
        const unorderedComparableSet = new Set(
          presentEntries.map((entry) => getComparableValue(entry.value, options, true)),
        );
        status =
          unorderedComparableSet.size === 1 ? "arrayOrderMismatch" : "valueMismatch";
      } else {
        status = "valueMismatch";
      }
    }
  }

  const distinctValueCount = new Set(
    presentEntries.map((entry) => getComparableValue(entry.value, options)),
  ).size;

  return {
    keyPath: path,
    namespace: getNamespace(path),
    status,
    valuesByFileId,
    distinctValueCount,
  };
}

function buildComparison(validFiles, options) {
  if (validFiles.length < 2) {
    return null;
  }

  const mapByFileId = {};
  validFiles.forEach((file) => {
    mapByFileId[file.id] = flattenYaml(file.parsed);
  });

  const allPaths = new Set();
  Object.values(mapByFileId).forEach((keyMap) => {
    Object.keys(keyMap).forEach((path) => allPaths.add(path));
  });

  const rows = [...allPaths]
    .sort((left, right) => left.localeCompare(right))
    .map((path) => classifyRow(path, validFiles, mapByFileId, options));

  const summary = rows.reduce(
    (acc, row) => {
      acc.total += 1;
      acc[row.status] += 1;
      return acc;
    },
    {
      total: 0,
      match: 0,
      missing: 0,
      typeMismatch: 0,
      valueMismatch: 0,
      arrayOrderMismatch: 0,
    },
  );

  return { rows, summary };
}

function toCsv(rows, files) {
  const header = ["keyPath", "namespace", "status", ...files.map((file) => file.name)];
  const lines = [header];
  rows.forEach((row) => {
    const fileValues = files.map((file) => row.valuesByFileId[file.id]?.display ?? "MISSING");
    lines.push([row.keyPath, row.namespace, row.status, ...fileValues]);
  });
  return lines
    .map((line) =>
      line
        .map((item) => `"${String(item).replaceAll('"', '""')}"`)
        .join(","),
    )
    .join("\n");
}

function downloadFile(filename, contents, mimeType) {
  const blob = new Blob([contents], { type: mimeType });
  const url = URL.createObjectURL(blob);
  const anchor = document.createElement("a");
  anchor.href = url;
  anchor.download = filename;
  anchor.click();
  URL.revokeObjectURL(url);
}

function getStatusLabel(status) {
  switch (status) {
    case "typeMismatch":
      return "TYPE";
    case "valueMismatch":
      return "VALUE";
    case "arrayOrderMismatch":
      return "ORDER";
    case "missing":
      return "MISSING";
    case "match":
    default:
      return "MATCH";
  }
}

function doesRowMatchFilter(row, filter, search) {
  if (search) {
    const lowerSearch = search.toLowerCase();
    if (!row.keyPath.toLowerCase().includes(lowerSearch)) {
      return false;
    }
  }

  if (filter === "all") {
    return true;
  }
  if (filter === "differences") {
    return row.status !== "match";
  }
  return row.status === filter;
}

function App() {
  const [files, setFiles] = useState([]);
  const [pasteName, setPasteName] = useState("");
  const [pasteText, setPasteText] = useState("");
  const [activeFilter, setActiveFilter] = useState("differences");
  const [search, setSearch] = useState("");
  const [selectedPath, setSelectedPath] = useState("");
  const [hasCompared, setHasCompared] = useState(false);
  const [options, setOptions] = useState({
    baselineFileId: "",
    ignoreArrayOrder: false,
    ignoreWhitespaceInStrings: false,
    treatNullAndMissingAsEqual: false,
  });

  const validFiles = files.filter((file) => !file.parseError);

  const comparison = useMemo(
    () => buildComparison(validFiles, options),
    [validFiles, options],
  );

  const filteredRows = useMemo(() => {
    if (!comparison) {
      return [];
    }
    return comparison.rows.filter((row) => doesRowMatchFilter(row, activeFilter, search));
  }, [comparison, activeFilter, search]);

  const selectedRow = useMemo(
    () => comparison?.rows.find((row) => row.keyPath === selectedPath) ?? null,
    [comparison, selectedPath],
  );

  function upsertBaseline(nextFiles, preferredBaseline = options.baselineFileId) {
    const nextValidFiles = nextFiles.filter((file) => !file.parseError);
    const baselineExists = nextValidFiles.some((file) => file.id === preferredBaseline);
    const baselineFileId = baselineExists
      ? preferredBaseline
      : (nextValidFiles[0]?.id ?? "");
    setOptions((prev) => ({ ...prev, baselineFileId }));
  }

  function addYamlFile(name, rawText, sourceType) {
    const { parsed, parseError } = parseYamlText(rawText);
    const id =
      typeof crypto !== "undefined" && crypto.randomUUID
        ? crypto.randomUUID()
        : `${Date.now()}-${Math.random()}`;
    const nextFiles = [
      ...files,
      { id, name, sourceType, rawText, parsed, parseError },
    ];
    setFiles(nextFiles);
    upsertBaseline(nextFiles);
    setHasCompared(false);
  }

  async function onFileUpload(event) {
    const uploadedFiles = [...(event.target.files ?? [])];
    if (uploadedFiles.length === 0) {
      return;
    }
    const fileContents = await Promise.all(
      uploadedFiles.map(async (file) => ({
        name: file.name,
        text: await file.text(),
      })),
    );
    fileContents.forEach((fileData) => {
      addYamlFile(fileData.name, fileData.text, "upload");
    });
    event.target.value = "";
  }

  function onAddPastedYaml() {
    if (!pasteText.trim()) {
      return;
    }
    const defaultName = `pasted-${files.length + 1}.yaml`;
    addYamlFile(pasteName.trim() || defaultName, pasteText, "paste");
    setPasteName("");
    setPasteText("");
  }

  function onRemoveFile(fileId) {
    const nextFiles = files.filter((file) => file.id !== fileId);
    setFiles(nextFiles);
    upsertBaseline(nextFiles);
    setHasCompared(false);
    if (selectedPath) {
      setSelectedPath("");
    }
  }

  function onCompare() {
    setHasCompared(true);
    if (filteredRows.length > 0 && !selectedPath) {
      setSelectedPath(filteredRows[0].keyPath);
    }
  }

  function getBaselineMatchIndicator(row, fileId) {
    const baselineFileId = options.baselineFileId;
    if (!baselineFileId || baselineFileId === fileId) {
      return "";
    }
    const baselineCell = row.valuesByFileId[baselineFileId];
    const currentCell = row.valuesByFileId[fileId];
    if (!baselineCell || !currentCell || baselineCell.missing || currentCell.missing) {
      return "";
    }
    return baselineCell.comparable === currentCell.comparable ? "==" : "!=";
  }

  return (
    <div className="page">
      <header>
        <h1>YAML Compare Web</h1>
        <p>Compare 2+ YAML files by key path and inspect value differences.</p>
      </header>

      <section className="card">
        <h2>1) Add YAML Files</h2>
        <div className="setup-row">
          <label className="upload">
            Upload YAML files
            <input type="file" accept=".yaml,.yml,text/yaml,text/plain" multiple onChange={onFileUpload} />
          </label>
        </div>
        <div className="paste-grid">
          <input
            type="text"
            placeholder="Optional pasted file name"
            value={pasteName}
            onChange={(event) => setPasteName(event.target.value)}
          />
          <button type="button" onClick={onAddPastedYaml}>
            Add pasted YAML
          </button>
        </div>
        <textarea
          rows={8}
          placeholder="Paste YAML content here"
          value={pasteText}
          onChange={(event) => setPasteText(event.target.value)}
        />

        <div className="file-list">
          {files.length === 0 && <p className="muted">No files added yet.</p>}
          {files.map((file) => (
            <div className="file-row" key={file.id}>
              <div>
                <strong>{file.name}</strong>{" "}
                <span className={`status ${file.parseError ? "error" : "ok"}`}>
                  {file.parseError ? "Parse error" : "Parsed"}
                </span>
                {file.parseError && <div className="error-text">{file.parseError}</div>}
              </div>
              <button type="button" onClick={() => onRemoveFile(file.id)}>
                Remove
              </button>
            </div>
          ))}
        </div>
      </section>

      <section className="card">
        <h2>2) Compare Options</h2>
        <div className="baseline-row">
          <label>Baseline file:</label>
          <select
            value={options.baselineFileId}
            onChange={(event) =>
              setOptions((prev) => ({ ...prev, baselineFileId: event.target.value }))
            }
            disabled={validFiles.length === 0}
          >
            {validFiles.length === 0 && <option value="">No valid files</option>}
            {validFiles.map((file) => (
              <option key={file.id} value={file.id}>
                {file.name}
              </option>
            ))}
          </select>
        </div>

        <div className="option-grid">
          <label>
            <input
              type="checkbox"
              checked={options.ignoreArrayOrder}
              onChange={(event) =>
                setOptions((prev) => ({ ...prev, ignoreArrayOrder: event.target.checked }))
              }
            />
            Ignore array order
          </label>
          <label>
            <input
              type="checkbox"
              checked={options.ignoreWhitespaceInStrings}
              onChange={(event) =>
                setOptions((prev) => ({
                  ...prev,
                  ignoreWhitespaceInStrings: event.target.checked,
                }))
              }
            />
            Ignore string whitespace differences
          </label>
          <label>
            <input
              type="checkbox"
              checked={options.treatNullAndMissingAsEqual}
              onChange={(event) =>
                setOptions((prev) => ({
                  ...prev,
                  treatNullAndMissingAsEqual: event.target.checked,
                }))
              }
            />
            Treat null and missing as equal
          </label>
        </div>

        <button
          type="button"
          className="primary"
          disabled={validFiles.length < 2}
          onClick={onCompare}
        >
          Compare ({validFiles.length} valid files)
        </button>
      </section>

      {hasCompared && comparison && (
        <section className="card">
          <h2>3) Comparison Results</h2>
          <div className="summary">
            <span>Total: {comparison.summary.total}</span>
            <span>Differences: {comparison.summary.total - comparison.summary.match}</span>
            <span>Missing: {comparison.summary.missing}</span>
            <span>Type: {comparison.summary.typeMismatch}</span>
            <span>Value: {comparison.summary.valueMismatch}</span>
            <span>Order: {comparison.summary.arrayOrderMismatch}</span>
          </div>

          <div className="controls">
            <div className="filters">
              {FILTERS.map((filter) => (
                <button
                  key={filter.key}
                  type="button"
                  className={activeFilter === filter.key ? "active" : ""}
                  onClick={() => setActiveFilter(filter.key)}
                >
                  {filter.label}
                </button>
              ))}
            </div>
            <input
              type="search"
              placeholder="Search key path..."
              value={search}
              onChange={(event) => setSearch(event.target.value)}
            />
            <button
              type="button"
              onClick={() =>
                downloadFile(
                  "yaml-diff.json",
                  JSON.stringify(
                    {
                      summary: comparison.summary,
                      rows: filteredRows,
                    },
                    null,
                    2,
                  ),
                  "application/json",
                )
              }
            >
              Export JSON
            </button>
            <button
              type="button"
              onClick={() =>
                downloadFile(
                  "yaml-diff.csv",
                  toCsv(filteredRows, validFiles),
                  "text/csv;charset=utf-8",
                )
              }
            >
              Export CSV
            </button>
          </div>

          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Key Path</th>
                  <th>Status</th>
                  {validFiles.map((file) => (
                    <th key={file.id}>
                      {file.name}
                      {file.id === options.baselineFileId ? " (baseline)" : ""}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {filteredRows.length === 0 && (
                  <tr>
                    <td colSpan={2 + validFiles.length}>No rows match the current filter.</td>
                  </tr>
                )}
                {filteredRows.map((row) => (
                  <tr
                    key={row.keyPath}
                    className={selectedPath === row.keyPath ? "selected" : ""}
                    onClick={() => setSelectedPath(row.keyPath)}
                  >
                    <td>
                      <code>{row.keyPath}</code>
                      <div className="muted">{row.namespace}</div>
                    </td>
                    <td>
                      <span className={`badge ${row.status}`}>{getStatusLabel(row.status)}</span>
                    </td>
                    {validFiles.map((file) => {
                      const cell = row.valuesByFileId[file.id];
                      const indicator = getBaselineMatchIndicator(row, file.id);
                      return (
                        <td
                          key={file.id}
                          className={cell?.missing ? "missing-cell" : ""}
                          title={cell?.display ?? "MISSING"}
                        >
                          {cell?.display ?? "MISSING"}
                          {indicator && <span className="indicator">{indicator}</span>}
                        </td>
                      );
                    })}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {selectedRow && (
            <div className="detail">
              <h3>Selected Key</h3>
              <p>
                <strong>{selectedRow.keyPath}</strong> ({selectedRow.namespace}) -{" "}
                {getStatusLabel(selectedRow.status)}
              </p>
              <p>Distinct normalized values: {selectedRow.distinctValueCount}</p>
              <ul>
                {validFiles.map((file) => {
                  const cell = selectedRow.valuesByFileId[file.id];
                  return (
                    <li key={file.id}>
                      <strong>{file.name}:</strong> {cell?.display ?? "MISSING"}
                    </li>
                  );
                })}
              </ul>
            </div>
          )}
        </section>
      )}
    </div>
  );
}

export default App;
