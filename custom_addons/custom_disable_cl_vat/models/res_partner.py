import re
from odoo import api, models

_R_ONLY_DIGITS_K = re.compile(r'[^0-9K]')

class ResPartner(models.Model):
    _inherit = 'res.partner'

    # 1) Override del normalizador que llama base_vat.write()
    def _fix_vat_number(self, vat, country_id):
        country = self.env['res.country'].browse(country_id) if country_id else False
        if country and country.code == 'CL' and vat:
            # quita CL y deja solo dígitos + K
            raw = str(vat).upper().replace('CL', '')
            clean = _R_ONLY_DIGITS_K.sub('', raw)
            if len(clean) >= 2:
                number, dv = clean[:-1], clean[-1]
                # <<< formato que pasa el validador CHL: CL########-# >>>
                return f"CL{number}{dv}"
        # para otros países, usa el comportamiento estándar
        return super()._fix_vat_number(vat, country_id)

    # 2) (Opcional pero recomendable) Mantener document_number “bonito” sin CL
    def _normalize_document_number_if_cl(self, vals, partner=None):
        vals = dict(vals or {})
        country_id = vals.get('country_id') or (partner and partner.country_id.id)
        if not country_id:
            return vals
        if self.env['res.country'].browse(country_id).code != 'CL':
            return vals

        dn = (vals.get('document_number') or '').upper()
        if dn.startswith('CL'):
            vals['document_number'] = dn.replace('CL', '', 1)  # quita el prefijo
        return vals

    @api.model
    def create(self, vals):
        vals = self._normalize_document_number_if_cl(vals)
        return super().create(vals)

    def write(self, vals):
        vals = self._normalize_document_number_if_cl(vals)
        return super().write(vals)