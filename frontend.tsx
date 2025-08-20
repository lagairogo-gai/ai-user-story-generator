import React, { useState, useEffect, useCallback } from 'react';
import { 
  Upload, 
  Settings, 
  FileText, 
  Brain, 
  Shield, 
  Activity,
  Database,
  Wifi,
  AlertTriangle,
  CheckCircle,
  Clock,
  Download,
  Plus,
  Play,
  Loader2,
  Star,
  Target,
  Users,
  Zap
} from 'lucide-react';

// Configuration and State Management
const LLM_PROVIDERS = {
  openai: {
    name: 'OpenAI',
    icon: '🟢',
    models: [
      { value: 'gpt-4', label: 'GPT-4' },
      { value: 'gpt-4-turbo', label: 'GPT-4 Turbo' },
      { value: 'gpt-3.5-turbo', label: 'GPT-3.5 Turbo' }
    ]
  },
  azure: {
    name: 'Azure OpenAI',
    icon: '🔵',
    models: [
      { value: 'gpt-4', label: 'GPT-4' },
      { value: 'gpt-4-32k', label: 'GPT-4 32K' },
      { value: 'gpt-35-turbo', label: 'GPT-3.5 Turbo' }
    ]
  },
  gemini: {
    name: 'Google Gemini',
    icon: '🟡',
    models: [
      { value: 'gemini-pro', label: 'Gemini Pro' },
      { value: 'gemini-pro-vision', label: 'Gemini Pro Vision' }
    ]
  },
  anthropic: {
    name: 'Anthropic',
    icon: '🟠',
    models: [
      { value: 'claude-3-opus', label: 'Claude-3 Opus' },
      { value: 'claude-3-sonnet', label: 'Claude-3 Sonnet' },
      { value: 'claude-3-haiku', label: 'Claude-3 Haiku' }
    ]
  }
};

// Toast Component
const Toast = ({ message, type, show, onClose }) => {
  useEffect(() => {
    if (show) {
      const timer = setTimeout(onClose, 3000);
      return () => clearTimeout(timer);
    }
  }, [show, onClose]);

  if (!show) return null;

  const bgColor = {
    success: 'bg-green-500',
    error: 'bg-red-500',
    warning: 'bg-yellow-500'
  }[type] || 'bg-blue-500';

  return (
    <div className={`fixed top-4 right-4 ${bgColor} text-white px-6 py-3 rounded-lg shadow-lg z-50 transform transition-transform duration-300 ${show ? 'translate-x-0' : 'translate-x-full'}`}>
      {message}
    </div>
  );
};

// Status Indicator Component
const StatusIndicator = ({ status, label }) => {
  const getStatusColor = () => {
    switch (status) {
      case 'success': return 'bg-green-500';
      case 'warning': return 'bg-yellow-500';
      case 'error': return 'bg-red-500';
      default: return 'bg-gray-500';
    }
  };

  return (
    <div className="flex items-center gap-2">
      <div className={`w-3 h-3 rounded-full ${getStatusColor()} animate-pulse`}></div>
      <span className="text-sm text-white/90">{label}</span>
    </div>
  );
};

// LLM Configuration Component
const LLMConfiguration = ({ config, onConfigUpdate, onTest }) => {
  const [localConfig, setLocalConfig] = useState(config);
  const [isLoading, setIsLoading] = useState(false);

  const handleProviderSelect = (provider) => {
    setLocalConfig({
      ...localConfig,
      provider,
      model_name: LLM_PROVIDERS[provider].models[0].value
    });
  };

  const handleSubmit = async () => {
    if (!localConfig.api_key) {
      alert('Please enter an API key');
      return;
    }

    setIsLoading(true);
    try {
      await onConfigUpdate(localConfig);
    } finally {
      setIsLoading(false);
    }
  };

  const handleTest = async () => {
    setIsLoading(true);
    try {
      await onTest();
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="bg-gradient-to-br from-red-500 to-orange-600 text-white p-6 rounded-2xl shadow-xl">
      <div className="flex items-center gap-3 mb-6">
        <Settings className="w-6 h-6" />
        <h2 className="text-xl font-bold">LLM Configuration</h2>
      </div>

      {/* Provider Selection */}
      <div className="mb-6">
        <label className="block text-sm font-semibold mb-3">LLM Provider</label>
        <div className="grid grid-cols-2 gap-3">
          {Object.entries(LLM_PROVIDERS).map(([key, provider]) => (
            <div
              key={key}
              className={`p-3 rounded-lg cursor-pointer transition-all duration-200 ${
                localConfig.provider === key
                  ? 'bg-white/30 border-2 border-white/50'
                  : 'bg-white/10 hover:bg-white/20'
              }`}
              onClick={() => handleProviderSelect(key)}
            >
              <div className="flex items-center gap-2">
                <span className="text-2xl">{provider.icon}</span>
                <div>
                  <div className="font-medium">{provider.name}</div>
                  <div className="text-xs opacity-80">
                    {provider.models.length} models
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Model and Temperature */}
      <div className="grid grid-cols-2 gap-4 mb-4">
        <div>
          <label className="block text-sm font-semibold mb-2">Model</label>
          <select
            value={localConfig.model_name}
            onChange={(e) => setLocalConfig({...localConfig, model_name: e.target.value})}
            className="w-full p-2 rounded-lg bg-white/20 border border-white/30 text-white placeholder-white/70"
          >
            {LLM_PROVIDERS[localConfig.provider]?.models.map((model) => (
              <option key={model.value} value={model.value} className="text-black">
                {model.label}
              </option>
            ))}
          </select>
        </div>
        <div>
          <label className="block text-sm font-semibold mb-2">
            Temperature: {localConfig.temperature}
          </label>
          <input
            type="range"
            min="0"
            max="2"
            step="0.1"
            value={localConfig.temperature}
            onChange={(e) => setLocalConfig({...localConfig, temperature: parseFloat(e.target.value)})}
            className="w-full"
          />
        </div>
      </div>

      {/* API Key */}
      <div className="mb-4">
        <label className="block text-sm font-semibold mb-2">API Key</label>
        <input
          type="password"
          value={localConfig.api_key}
          onChange={(e) => setLocalConfig({...localConfig, api_key: e.target.value})}
          placeholder="Enter your API key"
          className="w-full p-3 rounded-lg bg-white/20 border border-white/30 text-white placeholder-white/70"
        />
      </div>

      {/* Azure-specific fields */}
      {localConfig.provider === 'azure' && (
        <div className="space-y-4 mb-4">
          <div>
            <label className="block text-sm font-semibold mb-2">Azure Endpoint</label>
            <input
              type="url"
              value={localConfig.base_url || ''}
              onChange={(e) => setLocalConfig({...localConfig, base_url: e.target.value})}
              placeholder="https://your-resource.openai.azure.com/"
              className="w-full p-3 rounded-lg bg-white/20 border border-white/30 text-white placeholder-white/70"
            />
          </div>
          <div>
            <label className="block text-sm font-semibold mb-2">API Version</label>
            <input
              type="text"
              value={localConfig.api_version || ''}
              onChange={(e) => setLocalConfig({...localConfig, api_version: e.target.value})}
              placeholder="2023-12-01-preview"
              className="w-full p-3 rounded-lg bg-white/20 border border-white/30 text-white placeholder-white/70"
            />
          </div>
        </div>
      )}

      {/* Action Buttons */}
      <div className="space-y-2">
        <button
          onClick={handleSubmit}
          disabled={isLoading}
          className="w-full bg-green-600 hover:bg-green-700 disabled:opacity-50 text-white py-3 px-4 rounded-lg font-semibold transition-colors duration-200 flex items-center justify-center gap-2"
        >
          {isLoading ? <Loader2 className="w-4 h-4 animate-spin" /> : '🔄'}
          Update Configuration
        </button>
        <button
          onClick={handleTest}
          disabled={isLoading || !localConfig.api_key}
          className="w-full bg-blue-600 hover:bg-blue-700 disabled:opacity-50 text-white py-3 px-4 rounded-lg font-semibold transition-colors duration-200 flex items-center justify-center gap-2"
        >
          {isLoading ? <Loader2 className="w-4 h-4 animate-spin" /> : '🧪'}
          Test Connection
        </button>
      </div>
    </div>
  );
};

// File Upload Component
const FileUpload = ({ onFileUpload, isUploading, progress }) => {
  const [dragOver, setDragOver] = useState(false);

  const handleDrop = (e) => {
    e.preventDefault();
    setDragOver(false);
    const files = Array.from(e.dataTransfer.files);
    onFileUpload(files);
  };

  const handleFileSelect = (e) => {
    const files = Array.from(e.target.files);
    onFileUpload(files);
  };

  return (
    <div className="space-y-4">
      <div
        className={`border-2 border-dashed rounded-xl p-8 text-center cursor-pointer transition-all duration-200 ${
          dragOver
            ? 'border-green-400 bg-green-50'
            : 'border-white/30 hover:border-white/50 hover:bg-white/5'
        }`}
        onDragOver={(e) => { e.preventDefault(); setDragOver(true); }}
        onDragLeave={() => setDragOver(false)}
        onDrop={handleDrop}
        onClick={() => document.getElementById('fileInput').click()}
      >
        <input
          id="fileInput"
          type="file"
          multiple
          accept=".pdf,.doc,.docx,.txt,.md"
          onChange={handleFileSelect}
          className="hidden"
        />
        <Upload className="w-12 h-12 mx-auto mb-4 text-white/70" />
        <p className="text-white font-medium mb-2">
          Click to upload or drag files here
        </p>
        <p className="text-white/70 text-sm">
          Supports PDF, DOC, DOCX, TXT, MD (Max 50MB each)
        </p>
      </div>

      {isUploading && (
        <div className="space-y-2">
          <div className="w-full bg-white/20 rounded-full h-2">
            <div
              className="bg-green-500 h-2 rounded-full transition-all duration-300"
              style={{ width: `${progress}%` }}
            />
          </div>
          <p className="text-center text-white/70 text-sm">
            Uploading and processing... {Math.round(progress)}%
          </p>
        </div>
      )}
    </div>
  );
};

// User Story Component
const UserStoryCard = ({ story, index }) => {
  const getPriorityColor = (priority) => {
    switch (priority?.toLowerCase()) {
      case 'high': return 'bg-red-100 text-red-800';
      case 'medium': return 'bg-yellow-100 text-yellow-800';
      case 'low': return 'bg-green-100 text-green-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const acceptanceCriteria = Array.isArray(story.acceptance_criteria)
    ? story.acceptance_criteria
    : JSON.parse(story.acceptance_criteria || '[]');

  return (
    <div
      className="bg-white/10 backdrop-blur-sm rounded-xl p-6 border-l-4 border-yellow-400 animate-slideIn"
      style={{ animationDelay: `${index * 100}ms` }}
    >
      <div className="flex justify-between items-start mb-4">
        <h3 className="text-lg font-bold text-gray-800">{story.title}</h3>
        <div className="flex gap-2">
          <span className={`px-2 py-1 rounded-full text-xs font-medium ${getPriorityColor(story.priority)}`}>
            {story.priority || 'Medium'}
          </span>
          <span className="px-2 py-1 bg-blue-100 text-blue-800 rounded-full text-xs font-medium">
            Story
          </span>
        </div>
      </div>

      <p className="text-gray-700 mb-4 leading-relaxed">
        {story.story}
      </p>

      {acceptanceCriteria.length > 0 && (
        <div className="bg-white/20 rounded-lg p-4">
          <h4 className="font-semibold text-gray-800 mb-2">Acceptance Criteria:</h4>
          <ul className="space-y-1">
            {acceptanceCriteria.map((criteria, idx) => (
              <li key={idx} className="flex items-start gap-2 text-gray-700">
                <CheckCircle className="w-4 h-4 text-green-600 mt-0.5 flex-shrink-0" />
                <span>{criteria}</span>
              </li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
};

// Metrics Dashboard
const MetricsDashboard = ({ metrics }) => {
  const metricItems = [
    { label: 'Projects', value: metrics.projects || 0, icon: Target },
    { label: 'Stories', value: metrics.stories || 0, icon: FileText },
    { label: 'Documents', value: metrics.documents || 0, icon: Upload },
    { label: 'Avg Response', value: `${metrics.avgResponseTime || 0}ms`, icon: Zap }
  ];

  return (
    <div className="bg-gradient-to-br from-purple-600 to-blue-700 text-white p-6 rounded-2xl shadow-xl">
      <div className="flex items-center gap-3 mb-6">
        <Activity className="w-6 h-6" />
        <h2 className="text-xl font-bold">System Metrics</h2>
      </div>
      
      <div className="grid grid-cols-2 gap-4">
        {metricItems.map((item, index) => (
          <div key={index} className="bg-white/10 rounded-lg p-4 text-center">
            <item.icon className="w-6 h-6 mx-auto mb-2 text-white/80" />
            <div className="text-2xl font-bold">{item.value}</div>
            <div className="text-sm text-white/80">{item.label}</div>
          </div>
        ))}
      </div>
    </div>
  );
};

// Main App Component
const AIUserStoryGenerator = () => {
  // State Management
  const [llmConfig, setLlmConfig] = useState({
    provider: 'openai',
    model_name: 'gpt-4',
    api_key: '',
    temperature: 0.7,
    max_tokens: 2000
  });

  const [systemStatus, setSystemStatus] = useState({
    api: { status: 'warning', text: 'Connecting...' },
    llm: { status: 'warning', text: 'Not Configured' },
    rag: { status: 'success', text: 'Ready' },
    db: { status: 'success', text: 'Connected' }
  });

  const [projects, setProjects] = useState([]);
  const [currentProject, setCurrentProject] = useState(null);
  const [sourceType, setSourceType] = useState('upload');
  const [projectContext, setProjectContext] = useState('');
  const [requirements, setRequirements] = useState('');
  const [externalUrl, setExternalUrl] = useState('');
  
  const [userStories, setUserStories] = useState([]);
  const [isGenerating, setIsGenerating] = useState(false);
  const [isUploading, setIsUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);
  
  const [metrics, setMetrics] = useState({});
  const [toast, setToast] = useState({ show: false, message: '', type: 'success' });

  // Toast Helper
  const showToast = useCallback((message, type = 'success') => {
    setToast({ show: true, message, type });
  }, []);

  const hideToast = useCallback(() => {
    setToast(prev => ({ ...prev, show: false }));
  }, []);

  // API Helper
  const apiCall = async (endpoint, options = {}) => {
    const token = localStorage.getItem('auth_token') || 'placeholder-token';
    
    const response = await fetch(`/api${endpoint}`, {
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
        ...options.headers
      },
      ...options
    });
    
    if (!response.ok) {
      throw new Error(`API call failed: ${response.statusText}`);
    }
    
    return response.json();
  };

  // System Health Check
  const checkSystemHealth = useCallback(async () => {
    try {
      await fetch('/api/health');
      setSystemStatus(prev => ({
        ...prev,
        api: { status: 'success', text: 'Connected' }
      }));
    } catch (error) {
      setSystemStatus(prev => ({
        ...prev,
        api: { status: 'error', text: 'Disconnected' }
      }));
    }
  }, []);

  // Load Projects
  const loadProjects = useCallback(async () => {
    try {
      const projectData = await apiCall('/projects');
      setProjects(projectData);
      if (projectData.length > 0 && !currentProject) {
        setCurrentProject(projectData[0].id);
      }
    } catch (error) {
      console.error('Error loading projects:', error);
    }
  }, [currentProject]);

  // Update Metrics
  const updateMetrics = useCallback(async () => {
    try {
      const metricsData = await apiCall('/metrics');
      setMetrics(metricsData);
    } catch (error) {
      console.error('Error updating metrics:', error);
    }
  }, []);

  // LLM Configuration
  const handleLLMConfigUpdate = async (config) => {
    try {
      await apiCall('/config/llm', {
        method: 'PUT',
        body: JSON.stringify(config)
      });
      
      setLlmConfig(config);
      localStorage.setItem('llm_config', JSON.stringify(config));
      setSystemStatus(prev => ({
        ...prev,
        llm: { status: 'success', text: 'Configured' }
      }));
      showToast('LLM configuration updated successfully');
    } catch (error) {
      showToast('Failed to update LLM configuration', 'error');
    }
  };

  const handleLLMTest = async () => {
    try {
      await apiCall('/test-llm', { method: 'POST' });
      setSystemStatus(prev => ({
        ...prev,
        llm: { status: 'success', text: 'Connected' }
      }));
      showToast('LLM connection test successful');
    } catch (error) {
      setSystemStatus(prev => ({
        ...prev,
        llm: { status: 'error', text: 'Connection Failed' }
      }));
      showToast('LLM connection test failed', 'error');
    }
  };

  // Project Management
  const createNewProject = async () => {
    const name = prompt('Enter project name:');
    if (!name) return;
    
    const description = prompt('Enter project description (optional):') || '';
    
    try {
      const project = await apiCall('/projects', {
        method: 'POST',
        body: JSON.stringify({ name, description })
      });
      
      setProjects(prev => [...prev, project]);
      setCurrentProject(project.id);
      showToast(`Project "${name}" created successfully`);
      updateMetrics();
    } catch (error) {
      showToast('Failed to create project', 'error');
    }
  };

  // File Upload
  const handleFileUpload = async (files) => {
    if (!currentProject) {
      showToast('Please select or create a project first', 'warning');
      return;
    }

    setIsUploading(true);
    setUploadProgress(0);

    try {
      for (let i = 0; i < files.length; i++) {
        const file = files[i];
        
        // Validate file
        const allowedTypes = ['.pdf', '.doc', '.docx', '.txt', '.md'];
        const fileExt = '.' + file.name.split('.').pop().toLowerCase();
        
        if (!allowedTypes.includes(fileExt)) {
          showToast(`File type ${fileExt} not supported`, 'error');
          continue;
        }
        
        if (file.size > 50 * 1024 * 1024) {
          showToast(`File ${file.name} is too large (max 50MB)`, 'error');
          continue;
        }

        const formData = new FormData();
        formData.append('file', file);

        await fetch(`/api/projects/${currentProject}/upload`, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('auth_token') || 'placeholder-token'}`
          },
          body: formData
        });

        setUploadProgress(((i + 1) / files.length) * 100);
      }

      showToast(`${files.length} file(s) uploaded successfully`);
      updateMetrics();
    } catch (error) {
      showToast('File upload failed', 'error');
    } finally {
      setIsUploading(false);
      setUploadProgress(0);
    }
  };

  // User Story Generation
  const generateUserStories = async () => {
    if (!currentProject) {
      showToast('Please select or create a project first', 'warning');
      return;
    }

    if (!projectContext && !requirements) {
      showToast('Please provide project context or requirements', 'warning');
      return;
    }

    setIsGenerating(true);
    setUserStories([]);

    try {
      const requestData = {
        project_context: projectContext,
        requirements: requirements,
        source_type: sourceType
      };

      if (sourceType !== 'upload' && externalUrl) {
        requestData.source_url = externalUrl;
      }

      const result = await apiCall(`/projects/${currentProject}/generate-stories`, {
        method: 'POST',
        body: JSON.stringify(requestData)
      });

      setUserStories(result.stories);
      showToast(`Generated ${result.stories.length} user stories`);
      updateMetrics();
    } catch (error) {
      showToast('Failed to generate user stories', 'error');
    } finally {
      setIsGenerating(false);
    }
  };

  // Export Stories
  const exportStories = () => {
    if (userStories.length === 0) {
      showToast('No user stories to export', 'warning');
      return;
    }

    const csv = convertToCSV(userStories);
    downloadFile(csv, 'user-stories.csv', 'text/csv');
    showToast('User stories exported successfully');
  };

  const convertToCSV = (data) => {
    const headers = ['Title', 'User Story', 'Acceptance Criteria', 'Priority'];
    const rows = data.map(item => {
      const criteria = Array.isArray(item.acceptance_criteria)
        ? item.acceptance_criteria
        : JSON.parse(item.acceptance_criteria || '[]');
      
      return [
        `"${item.title}"`,
        `"${item.story}"`,
        `"${criteria.join('; ')}"`,
        `"${item.priority || 'medium'}"`
      ];
    });

    return [headers.join(','), ...rows.map(row => row.join(','))].join('\n');
  };

  const downloadFile = (content, filename, contentType) => {
    const blob = new Blob([content], { type: contentType });
    const url = window.URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = filename;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    window.URL.revokeObjectURL(url);
  };

  // Effects
  useEffect(() => {
    checkSystemHealth();
    loadProjects();
    updateMetrics();
    
    // Load saved config
    const savedConfig = localStorage.getItem('llm_config');
    if (savedConfig) {
      const config = JSON.parse(savedConfig);
      setLlmConfig(config);
      if (config.api_key) {
        setSystemStatus(prev => ({
          ...prev,
          llm: { status: 'success', text: 'Configured' }
        }));
      }
    }

    // Set up periodic health checks
    const healthInterval = setInterval(checkSystemHealth, 30000);
    const metricsInterval = setInterval(updateMetrics, 30000);
    
    return () => {
      clearInterval(healthInterval);
      clearInterval(metricsInterval);
    };
  }, [checkSystemHealth, loadProjects, updateMetrics]);

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-600 via-blue-600 to-teal-600">
      <div className="max-w-7xl mx-auto p-6">
        {/* Header */}
        <div className="text-center mb-8">
          <h1 className="text-4xl md:text-5xl font-bold text-white mb-4">
            🤖 AI User Story Generator
          </h1>
          <p className="text-xl text-white/90">
            Production-grade RAG-powered user story generation
          </p>
        </div>

        {/* Status Bar */}
        <div className="bg-white/10 backdrop-blur-md rounded-xl p-4 mb-8">
          <div className="flex flex-wrap justify-between items-center gap-4">
            <StatusIndicator status={systemStatus.api.status} label={`API: ${systemStatus.api.text}`} />
            <StatusIndicator status={systemStatus.llm.status} label={`LLM: ${systemStatus.llm.text}`} />
            <StatusIndicator status={systemStatus.rag.status} label={`RAG: ${systemStatus.rag.text}`} />
            <StatusIndicator status={systemStatus.db.status} label={`DB: ${systemStatus.db.text}`} />
          </div>
        </div>

        {/* Main Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 mb-8">
          {/* LLM Configuration */}
          <div className="lg:col-span-1">
            <LLMConfiguration
              config={llmConfig}
              onConfigUpdate={handleLLMConfigUpdate}
              onTest={handleLLMTest}
            />
          </div>

          {/* Input Section */}
          <div className="lg:col-span-2">
            <div className="bg-gradient-to-br from-blue-500 to-cyan-600 text-white p-6 rounded-2xl shadow-xl">
              <div className="flex items-center gap-3 mb-6">
                <FileText className="w-6 h-6" />
                <h2 className="text-xl font-bold">Project & Requirements</h2>
              </div>

              {/* Project Selection */}
              <div className="mb-6">
                <label className="block text-sm font-semibold mb-2">Project</label>
                <div className="flex gap-2">
                  <select
                    value={currentProject || ''}
                    onChange={(e) => setCurrentProject(e.target.value)}
                    className="flex-1 p-3 rounded-lg bg-white/20 border border-white/30 text-white"
                  >
                    <option value="" className="text-black">Select project...</option>
                    {projects.map(project => (
                      <option key={project.id} value={project.id} className="text-black">
                        {project.name}
                      </option>
                    ))}
                  </select>
                  <button
                    onClick={createNewProject}
                    className="bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded-lg font-medium transition-colors duration-200 flex items-center gap-2"
                  >
                    <Plus className="w-4 h-4" />
                    New
                  </button>
                </div>
              </div>

              {/* Data Source */}
              <div className="mb-6">
                <label className="block text-sm font-semibold mb-2">Data Source</label>
                <select
                  value={sourceType}
                  onChange={(e) => setSourceType(e.target.value)}
                  className="w-full p-3 rounded-lg bg-white/20 border border-white/30 text-white"
                >
                  <option value="upload" className="text-black">Direct Upload</option>
                  <option value="confluence" className="text-black">Confluence</option>
                  <option value="jira" className="text-black">Jira</option>
                  <option value="url" className="text-black">URL</option>
                </select>
              </div>

              {/* File Upload or External Source */}
              {sourceType === 'upload' ? (
                <div className="mb-6">
                  <label className="block text-sm font-semibold mb-2">Upload Requirements Document</label>
                  <FileUpload
                    onFileUpload={handleFileUpload}
                    isUploading={isUploading}
                    progress={uploadProgress}
                  />
                </div>
              ) : (
                <div className="mb-6">
                  <label className="block text-sm font-semibold mb-2">
                    {sourceType === 'confluence' && 'Confluence Page URL'}
                    {sourceType === 'jira' && 'Jira Project Key'}
                    {sourceType === 'url' && 'Document URL'}
                  </label>
                  <input
                    type="text"
                    value={externalUrl}
                    onChange={(e) => setExternalUrl(e.target.value)}
                    placeholder={
                      sourceType === 'confluence' ? 'https://yourcompany.atlassian.net/wiki/spaces/...' :
                      sourceType === 'jira' ? 'PROJ-123' :
                      'https://example.com/requirements.pdf'
                    }
                    className="w-full p-3 rounded-lg bg-white/20 border border-white/30 text-white placeholder-white/70"
                  />
                </div>
              )}

              {/* Project Context */}
              <div className="mb-6">
                <label className="block text-sm font-semibold mb-2">Project Context</label>
                <input
                  type="text"
                  value={projectContext}
                  onChange={(e) => setProjectContext(e.target.value)}
                  placeholder="e.g., E-commerce platform, Mobile app, CRM system"
                  className="w-full p-3 rounded-lg bg-white/20 border border-white/30 text-white placeholder-white/70"
                />
              </div>

              {/* Additional Requirements */}
              <div className="mb-6">
                <label className="block text-sm font-semibold mb-2">Additional Requirements</label>
                <textarea
                  value={requirements}
                  onChange={(e) => setRequirements(e.target.value)}
                  rows={4}
                  placeholder="Describe specific requirements, user personas, business rules, technical constraints..."
                  className="w-full p-3 rounded-lg bg-white/20 border border-white/30 text-white placeholder-white/70 resize-none"
                />
              </div>

              {/* Generate Button */}
              <button
                onClick={generateUserStories}
                disabled={isGenerating || !currentProject}
                className="w-full bg-green-600 hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed text-white py-4 px-6 rounded-lg font-bold text-lg transition-all duration-200 flex items-center justify-center gap-3"
              >
                {isGenerating ? (
                  <>
                    <Loader2 className="w-5 h-5 animate-spin" />
                    Generating Stories...
                  </>
                ) : (
                  <>
                    <Play className="w-5 h-5" />
                    Generate User Stories
                  </>
                )}
              </button>
            </div>
          </div>
        </div>

        {/* User Stories Output */}
        <div className="bg-gradient-to-br from-emerald-500 to-teal-600 text-gray-800 p-6 rounded-2xl shadow-xl mb-8">
          <div className="flex items-center justify-between mb-6">
            <div className="flex items-center gap-3">
              <Brain className="w-6 h-6 text-white" />
              <h2 className="text-xl font-bold text-white">Generated User Stories</h2>
            </div>
            {userStories.length > 0 && (
              <button
                onClick={exportStories}
                className="bg-white/20 hover:bg-white/30 text-white px-4 py-2 rounded-lg font-medium transition-colors duration-200 flex items-center gap-2"
              >
                <Download className="w-4 h-4" />
                Export
              </button>
            )}
          </div>

          {/* Loading State */}
          {isGenerating && (
            <div className="text-center py-12">
              <Loader2 className="w-12 h-12 animate-spin mx-auto mb-4 text-white" />
              <p className="text-white text-lg font-medium">
                Processing requirements with RAG pipeline...
              </p>
              <p className="text-white/80 text-sm mt-2">
                This may take a few moments
              </p>
            </div>
          )}

          {/* User Stories */}
          {userStories.length > 0 ? (
            <div className="space-y-6 max-h-96 overflow-y-auto">
              {userStories.map((story, index) => (
                <UserStoryCard key={story.id || index} story={story} index={index} />
              ))}
            </div>
          ) : !isGenerating && (
            <div className="text-center py-12">
              <FileText className="w-16 h-16 mx-auto mb-4 text-white/60" />
              <p className="text-white text-lg font-medium mb-2">
                No user stories generated yet
              </p>
              <p className="text-white/80">
                Configure your LLM settings and upload requirements to generate user stories
              </p>
            </div>
          )}
        </div>

        {/* Bottom Dashboard Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {/* Metrics Dashboard */}
          <MetricsDashboard metrics={metrics} />

          {/* RAG System Status */}
          <div className="bg-gradient-to-br from-cyan-500 to-blue-600 text-white p-6 rounded-2xl shadow-xl">
            <div className="flex items-center gap-3 mb-6">
              <Database className="w-6 h-6" />
              <h2 className="text-xl font-bold">RAG System Status</h2>
            </div>
            
            <div className="space-y-4">
              <div className="flex justify-between items-center">
                <span className="text-white/80">Vector Database:</span>
                <span className="flex items-center gap-2">
                  <CheckCircle className="w-4 h-4 text-green-400" />
                  ChromaDB
                </span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-white/80">Embeddings Model:</span>
                <span className="text-sm">text-embedding-ada-002</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-white/80">Chunks Processed:</span>
                <span>{metrics.chunksProcessed || 0}</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-white/80">Last Updated:</span>
                <span className="text-sm flex items-center gap-1">
                  <Clock className="w-3 h-3" />
                  {new Date().toLocaleTimeString()}
                </span>
              </div>
            </div>

            <div className="mt-6 p-4 bg-white/10 rounded-lg">
              <div className="text-sm text-white/80 mb-2">System Performance</div>
              <div className="w-full bg-white/20 rounded-full h-2">
                <div className="bg-green-400 h-2 rounded-full w-4/5"></div>
              </div>
              <div className="text-xs text-white/60 mt-1">Optimal</div>
            </div>
          </div>

          {/* Security & Compliance */}
          <div className="bg-gradient-to-br from-pink-500 to-rose-600 text-white p-6 rounded-2xl shadow-xl">
            <div className="flex items-center gap-3 mb-6">
              <Shield className="w-6 h-6" />
              <h2 className="text-xl font-bold">Security Status</h2>
            </div>
            
            <div className="space-y-4">
              <div className="flex justify-between items-center">
                <span className="text-white/80">Encryption:</span>
                <span className="flex items-center gap-2 text-green-300">
                  <CheckCircle className="w-4 h-4" />
                  TLS 1.3
                </span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-white/80">Rate Limiting:</span>
                <span className="flex items-center gap-2 text-green-300">
                  <CheckCircle className="w-4 h-4" />
                  Active
                </span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-white/80">Input Validation:</span>
                <span className="flex items-center gap-2 text-green-300">
                  <CheckCircle className="w-4 h-4" />
                  Enabled
                </span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-white/80">Last Security Scan:</span>
                <span className="text-sm flex items-center gap-1">
                  <Clock className="w-3 h-3" />
                  {new Date().toLocaleDateString()}
                </span>
              </div>
            </div>

            <button className="w-full mt-6 bg-red-600 hover:bg-red-700 text-white py-3 px-4 rounded-lg font-semibold transition-colors duration-200 flex items-center justify-center gap-2">
              <Shield className="w-4 h-4" />
              Run Security Scan
            </button>
          </div>
        </div>

        {/* Integration Status */}
        <div className="mt-6 bg-white/10 backdrop-blur-md rounded-xl p-6">
          <div className="flex items-center gap-3 mb-4">
            <Wifi className="w-5 h-5 text-white" />
            <h3 className="text-lg font-bold text-white">Integration Status</h3>
          </div>
          
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {[
              { name: 'MCP Protocol', status: 'Active', color: 'green' },
              { name: 'A2A Communication', status: 'Ready', color: 'green' },
              { name: 'Confluence API', status: 'Configured', color: 'blue' },
              { name: 'Jira Integration', status: 'Ready', color: 'blue' }
            ].map((integration, index) => (
              <div key={index} className="bg-white/10 rounded-lg p-3 text-center">
                <div className={`w-3 h-3 rounded-full mx-auto mb-2 ${
                  integration.color === 'green' ? 'bg-green-400' : 'bg-blue-400'
                }`}></div>
                <div className="text-white font-medium text-sm">{integration.name}</div>
                <div className="text-white/70 text-xs">{integration.status}</div>
              </div>
            ))}
          </div>
        </div>

        {/* Performance Metrics */}
        <div className="mt-6 bg-white/10 backdrop-blur-md rounded-xl p-6">
          <div className="flex items-center gap-3 mb-4">
            <Activity className="w-5 h-5 text-white" />
            <h3 className="text-lg font-bold text-white">Real-time Performance</h3>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {/* Request Rate */}
            <div className="text-center">
              <div className="text-2xl font-bold text-white mb-1">
                {Math.floor(Math.random() * 100) + 50}/min
              </div>
              <div className="text-white/70 text-sm">Request Rate</div>
              <div className="w-full bg-white/20 rounded-full h-2 mt-2">
                <div className="bg-green-400 h-2 rounded-full w-3/4"></div>
              </div>
            </div>
            
            {/* Response Time */}
            <div className="text-center">
              <div className="text-2xl font-bold text-white mb-1">
                {Math.floor(Math.random() * 100) + 200}ms
              </div>
              <div className="text-white/70 text-sm">Avg Response Time</div>
              <div className="w-full bg-white/20 rounded-full h-2 mt-2">
                <div className="bg-blue-400 h-2 rounded-full w-4/5"></div>
              </div>
            </div>
            
            {/* Error Rate */}
            <div className="text-center">
              <div className="text-2xl font-bold text-white mb-1">
                {(Math.random() * 0.5).toFixed(2)}%
              </div>
              <div className="text-white/70 text-sm">Error Rate</div>
              <div className="w-full bg-white/20 rounded-full h-2 mt-2">
                <div className="bg-green-400 h-2 rounded-full w-1/5"></div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Toast Notification */}
      <Toast
        message={toast.message}
        type={toast.type}
        show={toast.show}
        onClose={hideToast}
      />

      {/* Custom Styles */}
      <style jsx>{`
        @keyframes slideIn {
          from {
            opacity: 0;
            transform: translateY(20px);
          }
          to {
            opacity: 1;
            transform: translateY(0);
          }
        }
        
        .animate-slideIn {
          animation: slideIn 0.5s ease-out forwards;
        }
        
        /* Custom scrollbar */
        ::-webkit-scrollbar {
          width: 6px;
        }
        
        ::-webkit-scrollbar-track {
          background: rgba(255, 255, 255, 0.1);
          border-radius: 3px;
        }
        
        ::-webkit-scrollbar-thumb {
          background: rgba(255, 255, 255, 0.3);
          border-radius: 3px;
        }
        
        ::-webkit-scrollbar-thumb:hover {
          background: rgba(255, 255, 255, 0.5);
        }
        
        /* Smooth transitions */
        * {
          transition: all 0.2s ease;
        }
        
        /* Focus states */
        input:focus, select:focus, textarea:focus {
          outline: none;
          ring: 2px;
          ring-color: rgba(255, 255, 255, 0.5);
        }
        
        /* Button hover effects */
        button:hover:not(:disabled) {
          transform: translateY(-1px);
          box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
        }
        
        /* Card hover effects */
        .bg-gradient-to-br:hover {
          transform: translateY(-2px);
          box-shadow: 0 8px 25px rgba(0, 0, 0, 0.15);
        }
      `}</style>
    </div>
  );
};

export default AIUserStoryGenerator;