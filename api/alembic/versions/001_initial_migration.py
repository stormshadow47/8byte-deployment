from alembic import op
import sqlalchemy as sa

revision = '001'
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        'todo',
        sa.Column('id', sa.Integer(), nullable=True),
        sa.Column('title', sa.String(), nullable=False),
        sa.Column('completed', sa.Boolean(), nullable=False),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_todo_title'), 'todo', ['title'], unique=False)


def downgrade() -> None:
    op.drop_index(op.f('ix_todo_title'), table_name='todo')
    op.drop_table('todo')
