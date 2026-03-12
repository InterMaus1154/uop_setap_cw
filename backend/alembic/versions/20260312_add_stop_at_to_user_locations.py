"""
Add stop_at column to user_locations table
"""
from alembic import op
import sqlalchemy as sa

def upgrade():
    op.add_column('user_locations', sa.Column('stop_at', sa.DateTime(), nullable=True))

def downgrade():
    op.drop_column('user_locations', 'stop_at')
