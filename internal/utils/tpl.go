package utils

import (
	"html/template"
	"strings"
)

// FuncMap is a map of functions that can be used in templates.
var FuncMap = template.FuncMap{
	"lower":              strings.ToLower,
	"upper":              strings.ToUpper,
	"title":              strings.ToTitle,
	"lowerUnderline":     ToLowerUnderlinedNamer,
	"plural":             ToPlural,
	"lowerPlural":        ToLowerPlural,
	"lowerSpacePlural":   ToLowerSpacePlural,
	"lowerHyphensPlural": ToLowerHyphensPlural,
	"lowerCamel":         ToLowerCamel,
	"lowerSpace":         ToLowerSpacedNamer,
	"titleSpace":         ToTitleSpaceNamer,
	"replace": func(s, old, new string, n int) string {
		return strings.Replace(s, old, new, n)
	},
	"convIfCond":      tplConvToIfCond,
	"convSwaggerType": tplConvToSwaggerType,
	"contains":        func(s string, sub string) bool { return strings.Contains(s, sub) },
	"raw":             func(s string) template.HTML { return template.HTML(s) },
	"convGoTypeToTsType": func(goType string) string {
		if strings.Contains(goType, "int") || strings.Contains(goType, "float") {
			return "number"
		} else if goType == "bool" {
			return "boolean"
		}
		return "string"
	},
}

func tplConvToIfCond(t string) template.HTML {
	cond := `v != ""`
	if strings.HasPrefix(t, "*") {
		cond = `v != nil`
	} else if t == "string" {
		cond = `v != ""`
	} else if strings.Contains(t, "int") {
		cond = `v != 0`
	} else if strings.Contains(t, "float") {
		cond = `v != 0`
	} else if strings.Contains(t, "bool") {
		cond = `v`
	} else if t == "time.Time" {
		cond = `!v.IsZero()`
	}
	return template.HTML(cond)
}

func tplConvToSwaggerType(t string) string {
	if strings.Contains(t, "int") || strings.Contains(t, "float") {
		return "number"
	}
	return "string"
}
