package dal

import (
	"time"

	"{{.ModuleImportPath}}/schema"
	"gorm.io/gorm"
)

type cache{{.Name}} struct {
	Map  schema.{{.Name}}Map
	Time time.Time
}

type {{.Name}} struct {
	DB *gorm.DB
	cacheMap map[string]*cache{{.Name}} `wire:"-"`
}