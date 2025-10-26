# -*- coding: utf-8 -*-
from odoo import api, models

class ResPartner(models.Model):
    _inherit = "res.partner"

    def _normalize_cl_vat(self, vat):
        v = (vat or '').upper().strip()
        v = v.replace('.', '').replace(' ', '')
        # quitar CL si viene, y guiones para calcular clean
        if v.startswith('CL'):
            v = v[2:]
        v = v.replace('-', '')
        if not v:
            return vat
        # reponer guion verificador y prefijo CL
        cuerpo, dv = v[:-1], v[-1]
        return f"CL{cuerpo}-{dv}"

    @api.model_create_multi
    def create(self, vals_list):
        for vals in vals_list:
            # si el partner es chileno, normaliza ANTES de crear
            country_id = vals.get('country_id')
            if country_id:
                country = self.env['res.country'].browse(country_id)
                if country.code == 'CL' and vals.get('vat'):
                    vals['vat'] = self._normalize_cl_vat(vals['vat'])
        return super().create(vals_list)

    def write(self, vals):
        # normaliza ANTES del super para pasar la constraint de base_vat
        vals = vals.copy()
        if 'vat' in vals:
            # para cada registro, si es CL, normaliza
            for rec in self:
                if (rec.country_id and rec.country_id.code == 'CL') or \
                   (vals.get('country_id') and self.env['res.country'].browse(vals['country_id']).code == 'CL'):
                    vals['vat'] = self._normalize_cl_vat(vals['vat'])
                    break  # mismo valor para todos en esta llamada
        return super().write(vals)