import os
import sys
import unittest

# Ensure app directory and parent directory are in Python path
current_dir = os.path.dirname(os.path.abspath(__file__))
app_dir = os.path.dirname(current_dir)
repo_root = os.path.dirname(app_dir)

for path in [repo_root, app_dir]:
    if path not in sys.path:
        sys.path.insert(0, path)

try:
    from app.app import app
except (ImportError, AttributeError):
    try:
        from app import app
    except ImportError:
        import app

# Ensure app refers to the Flask instance, resolving any module vs package shadowing
if hasattr(app, 'app') and not hasattr(app, 'test_client'):
    app = app.app


class TestApp(unittest.TestCase):
    def setUp(self):
        self.client = app.test_client()

    def test_healthz(self):
        response = self.client.get('/healthz')
        self.assertEqual(response.status_code, 200)
        self.assertIn(b'healthy', response.data)

    def test_readyz(self):
        response = self.client.get('/readyz')
        self.assertEqual(response.status_code, 200)
        self.assertIn(b'ready', response.data)

    def test_metrics(self):
        response = self.client.get('/metrics')
        self.assertEqual(response.status_code, 200)

    def test_api_info(self):
        response = self.client.get('/api/info')
        self.assertEqual(response.status_code, 200)
        self.assertIn(b'complete-eks-devsecops-platform', response.data)


if __name__ == '__main__':
    unittest.main()
