"""add street and city to pins table

Revision ID: a1b2c3d4e5f6
Revises: 547c827d02d2
Create Date: 2026-05-11 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = 'a1b2c3d4e5f6'
down_revision: Union[str, Sequence[str], None] = '1a361f90b479'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('pins', sa.Column('pin_street', sa.String(length=200), nullable=True))
    op.add_column('pins', sa.Column('pin_city', sa.String(length=100), nullable=True))


def downgrade() -> None:
    op.drop_column('pins', 'pin_city')
    op.drop_column('pins', 'pin_street')
