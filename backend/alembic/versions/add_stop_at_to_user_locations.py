"""
Add stop_at field to user_locations table
"""
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = 'add_stop_at_to_user_locations'
down_revision = None  # Set this to the latest revision id
branch_labels = None
depends_on = None

def upgrade():
    op.add_column('user_locations', sa.Column('stop_at', sa.DateTime(), nullable=True))

def downgrade():
    op.drop_column('user_locations', 'stop_at')
