package dal

import (
	"context"
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

func (a *{{.Name}}) ResetMap() {
	a.cacheMap = nil
}

func (a *{{.Name}}) where(ctx context.Context, db *gorm.DB, params *schema.{{.Name}}QueryParam, opts ...schema.{{.Name}}QueryOptions) (*gorm.DB, error) {
	return db, nil
}