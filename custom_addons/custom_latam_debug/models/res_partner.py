from odoo import api, models
import debugpy

class ResPartner(models.Model):
    _inherit = 'res.partner'

    @api.constrains('vat', 'l10n_latam_identification_type_id')
    def check_vat(self):
        debugpy.breakpoint()  # <-- aquí se detendrá
        return super().check_vat()