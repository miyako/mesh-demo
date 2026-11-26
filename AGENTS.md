# Working on mesh-demo

This repository is a 4D project (project mode, sources only) that demonstrates the
`miyako/mesh` component. `Project/Sources/` is the source of truth; `Data/`, `Logs/`,
`DerivedData/`, `Components/` and `output/` are gitignored.

## Conventions

- Form class: `Project/Sources/Classes/StudioForm.4dm`. Control handlers in
  `Project/Sources/Forms/Studio/ObjectMethods/*.4dm` stay one-liners into the class.
- The form has `formClass: "StudioForm"`; open it with `DIALOG("Studio")` and **do not
  pass a formData object** — it would replace the class instance.
- Keep `Project/Sources/dependencies.json` declaring `miyako/mesh` (GitHub, tag `x.y.z`).

## Validation

```bash
tools/4dcatalog/xmllint --noout --nonet --dtdvalid .agents/schemas/4dcatalog/base.dtd \
  Project/Sources/catalog.4DCatalog
tools/4dform/boon -o simple .agents/schemas/4dform/formsSchema.json \
  Project/Sources/Forms/Studio/form.4DForm
tools/4dlsp/tool4d-lsp-stdio check-syntax --workspace Project/ --json
```

`check-syntax` always reports `cs.MeshPreview` as unknown: the LSP cannot see component
classes. That is expected, not a regression.

## Headless self-test

```bash
mv Project/Sources/dependencies.json /tmp/dep.bak   # tool4d cannot resolve GitHub deps
"/Applications/4D 21 R5 (100175)/tool4d.app/Contents/MacOS/tool4d" \
  --dataless --skip-onstartup --startup-method TestComponent \
  --project "$PWD/Project/mesh-demo.4DProject" --user-param /tmp/report.json
mv /tmp/dep.bak Project/Sources/dependencies.json
```

Expect `PASS 46 checks` on stdout plus a JSON report. The component must be installed at
`Components/mesh.4dbase`; the Dependency manager installs it when the project is opened
in the 4D IDE.

## Gotchas already paid for

See the chokepoint list in `README.md` (LSP blindness, `Longint`, `4D.File.name`,
temp-folder Null, `DIALOG` data override, `multiline` enum, 0-based collections).
